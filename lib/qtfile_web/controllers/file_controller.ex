defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  require Logger
  alias Qtfile.Settings
  alias Qtfile.FileProcessing.{Storage, Hashing, UploadState}
  alias Qtfile.Files
  @image_extensions ~w(.jpg .jpeg .png)
  @nice_mime_types ~w(text audio video image)

  def upload(conn, %{"room_id" => room_id} = params) do
    uploader_id = get_session(conn, :user_id)
    ip_address = Qtfile.Util.get_ip_address(conn)

    case validate_upload(room_id, uploader_id, ip_address) do
      {:ok, room} -> upload_validated(conn, params, room)
      _ -> json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  defp validate_upload(room_id, user_id, ip_address) do
    user_list =
      case user_id do
        nil -> []
        real_user_id ->
          case Qtfile.Accounts.get_user(real_user_id) do
            nil -> []
            user -> [user]
          end
      end
    case Qtfile.Rooms.uploadable_room(room_id, user_list) do
      {:ok, room} = r ->
        case Qtfile.Bans.get_bans_for(user_list ++ [ip_address], room) do
          [] -> r
          _ -> :error
        end
      _ = e -> e
    end
  end

  defp save_file_loop(conn, state, write, hash) do
    result = read_body(conn,
      length: 64 * 1024,
      read_length: 64 * 1024,
      read_timeout: 2048,
    )
    case result do
      {status, data, conn} ->
        {^status, state} = write.(state, data)
        hash = Hashing.update_hash(hash, data)
        case status do
          :more -> save_file_loop(conn, state, write, hash)
          :ok -> {:ok, state, {conn, hash}}
        end
      {:error, e} ->
        case e do
          :closed -> {:suspended, state, {conn, hash}}
          :timeout -> {:suspended, state, {conn, hash}}
        end
    end
  end

  defp upload_data(conn, room, filename, content_type, uuid, hash, size) do
    uploader_id = get_session(conn, :user_id)
    ip_address = Qtfile.Util.get_ip_address(conn)
    %{file_ttl: file_ttl} = room
    expiration_date = DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) + file_ttl)
      
    data =
      %{
        uuid: uuid,
        filename: filename,
        mime_type: content_type,
        location: room,
        size: size,
        ip_address: ip_address,
        expiration_date: expiration_date,
        hash: hash,
      }
    case uploader_id do
      nil -> data
      real_uid ->
        case Qtfile.Accounts.get_user(real_uid) do
          nil -> data
          real_user -> Map.put(data, :uploader, real_user)
        end
    end
  end

  defp new_upload(conn, unparsed_size) do
    uuid = Ecto.UUID.generate()
    {size, ""} = Integer.parse(unparsed_size)
    {:ok, upload_state} = Storage.new_file(uuid, size)
    hash = Hashing.initialise_hash()
    {uuid, size, hash, upload_state}
  end

  defp upload_validated(conn,
    %{
      "room_id" => room_id,
      "filename" => filename,
      "content_type" => content_type,
      "size" => unparsed_size,
      "offset" => unparsed_offset,
    } = params, room) do

    maybe_id = Map.fetch(params, "upload_id")
    {offset, ""} = Integer.parse(unparsed_offset)

    {uuid, size, hash, upload_state} =
      case maybe_id do
        {:ok, id} ->
          case UploadState.get(id) do
            {:ok, {hash, upload_state}} ->
              {
                Storage.get_id(upload_state),
                Storage.get_size(upload_state),
                hash,
                upload_state,
              }
            _ ->
              result = new_upload(conn, unparsed_size)
              {_, _, hash, upload_state} = result
              :ok = UploadState.put(id, {hash, upload_state})
              result
          end
        _ ->
          new_upload(conn, unparsed_size)
      end

    chunk_size = :erlang.binary_to_integer(hd(get_req_header(conn, "content-length")))

    Storage.write_chunk(upload_state, offset, chunk_size, fn(state, write) ->
      save_file_loop(conn, state, write, hash)
    end, fn(done, upload_state, result) ->
      case result do
        {conn, hash} ->
          case done do
            true ->
              case maybe_id do
                {:ok, id} -> UploadState.put(id, {hash, upload_state})
                _ -> nil
              end

              hash = Hashing.finalise_hash(hash)
              file_data = upload_data(conn, room, filename, content_type, uuid, hash, size)

              case Files.create_file(file_data) do
                {:ok, file} ->
                  :ok = Qtfile.FileProcessing.UploadEvent.notify_upload(file)
                {:error, changeset} ->
                  Logger.error("failed to add file to db")
                  Logger.error(inspect(changeset))
                  raise "file creation db error"
              end

              case maybe_id do
                {:ok, id} -> UploadState.delete(id)
                _ -> nil
              end

              json conn, %{success: true, done: true}
            false ->
              {:ok, id} = maybe_id
              UploadState.put(id, {hash, upload_state})
              json conn, %{success: true, done: false}
          end
        :offset_incorrect ->
          json conn,
          %{
            success: false,
            done: false,
            offset: Storage.get_offset(upload_state),
          }
      end
    end)
  end

  defp upload_validated(conn,
    %{
      "room_id" => _,
      "filename" => _,
    } = params, room) do
    upload_validated(conn,
      params
      |> Map.put_new("content_type", nil),
      room)
  end

  defp filter_downloadable(conn, uuid) do
    filter_setting("anon_download", conn, uuid)
  end

  defp filter_viewable(conn, uuid) do
    filter_setting("anon_view", conn, uuid)
  end

  defp filter_setting(key, conn, uuid) do
    logged_in =
      case get_session(conn, :user_id) do
        nil -> false
        id ->
          case Qtfile.Accounts.get_user(id) do
            %Qtfile.Accounts.User{} -> true
            _ -> false
          end
      end

    file = Files.get_file_by_uuid(uuid)

    unless logged_in ||
    (file != nil && Qtfile.Rooms.get_setting_value!(key, file.location)) do
      conn = conn
      |> send_resp(:forbidden, "Not logged in")
      |> halt()
      {conn, nil}
    else
      unless file != nil do
        conn = conn
        |> put_status(404)
        |> text("file not found!")
        {conn, nil}
      else
        {conn, file}
      end
    end
  end

  defp compare_mime_type({type1, subtype1, params1}, {type2, subtype2, params2}) do
    case compare_type(type1, type2) do
      {:not_eq, r} -> r
      :eq ->
        case compare_type(subtype1, subtype2) do
          {:not_eq, r} -> r
          :eq -> compare_mime_type_params(params1, params2)
        end
    end
  end

  defp compare_type(a, b) do
    case {a, b} do
      {"*", "*"} -> :eq
      {_, "*"} -> {:not_eq, true}
      {"*", _} -> {:not_eq, false}
      {x, y} -> if x == y do
        :eq
      else
        {:not_eq, false}
      end
    end
  end

  defp compare_mime_type_params(a, b) do
    [{q1, rest1}, {q2, rest2}] = Enum.map([a, b], &get_quality/1)
    if q1 == q2 do
      rest1 == rest2
    else
      q1 >= q2
    end
  end

  defp get_quality(params) do
    case params do
      [{"q", v_str} | rest] ->
        case Float.parse(v_str) do
          {v, ""} -> {v, rest}
          _ -> {1.0, rest}
        end
      x -> {1.0, x}
    end
  end

  def match_type(a, b) do
    case {a, b} do
      {"*", _} -> true
      {_, "*"} -> true
      {x, y} -> x == y
    end
  end

  defp match_mime_type({type1, subtype1, _}, {type2, subtype2, _}) do
    if match_type(type1, type2) do
      match_type(subtype1, subtype2)
    else
      false
    end
  end

  defp process_mime_type(m) do
    [x, y_original] = String.split(m, "/")
    [y | params_original] = String.split(y_original, ";")

    params = Enum.map(params_original, fn(param) ->
      [k, v] = String.split(param, "=")
      {k, v}
    end)

    {x, y, params}
  end

  defp find_right_preview(mime_types, previews) do
    sorted_mime_types = Enum.sort(mime_types, &compare_mime_type/2)

    linear_search(fn(m1) ->
      r =
        linear_search(fn({m2, p}) ->
          if match_mime_type(m1, m2) do
            {:ok, p}
          else
            :error
          end
        end, previews)

      case r do
        {:found, p} -> {:ok, p}
        :not_found -> :error
      end
    end, sorted_mime_types)
  end

  defp linear_search(test, [x | xs]) do
    case test.(x) do
      {:ok, v} -> {:found, v}
      :error -> linear_search(test, xs)
    end
  end

  defp linear_search(_, []) do
    :not_found
  end

  def download_preview(conn, %{"uuid" => uuid, "type" => type}) do
    {conn, result} = filter_viewable(conn, uuid)

    case result do
      nil -> conn
      file ->
        mime_types =
          Enum.flat_map(get_req_header(conn, "accept"), fn(header) ->
            Enum.map(String.split(header, ","), &process_mime_type/1)
          end)

        previews = Files.get_previews_by_file_type(file, type)

        preview =
          case mime_types do
            [] ->
              case previews do
                [p | ps] -> {:found, p}
                [] -> :not_found
              end
            _ ->
              processed_previews =
                Enum.map(previews, fn(p) ->
                  {process_mime_type(p.mime_type), p}
                end)

              find_right_preview(mime_types, processed_previews)
          end

        case preview do
          {:found, preview} ->
            ext =
              case preview.mime_type do
                "image/jpeg" -> "jpg"
                "video/webm" -> "webm"
                "video/mp4" -> "mp4"
              end

            path = "uploads/previews/" <> uuid <> "." <> ext
            send_file(conn, 200, path)
          :not_found ->
            conn
            |> put_status(406)
            |> text("cannot provide file in requested format")
        end
    end
  end

  def download(conn, %{"uuid" => uuid, "realfilename" => _realfilename}) do
    conn = put_resp_header(conn, "Accept-Ranges", "bytes")
    {conn, result} = filter_downloadable(conn, uuid)
    case result do
      nil -> conn
      file ->
        absolute_path = "uploads/" <> uuid

        mime_type = file.mime_type

        nice_file =
          case mime_type do
            nil -> false
            _ ->
              case String.split(mime_type, "/") do
                [type, _] -> Enum.member?(@nice_mime_types, type)
                _ -> false
              end
          end

        conn = unless mime_type == nil do
          put_resp_content_type(conn, mime_type)
        else
          put_resp_content_type(conn, "application/octet-stream")
        end

        disposition = if nice_file do "inline" else "attachment" end
        filename = "\"" <> URI.encode(file.filename) <> "\""
        conn = put_resp_header(conn, "Content-Disposition", disposition <> "; filename=" <> filename)

        ranges = get_req_header(conn, "range")

        conn =
          with [range | _] <- ranges,
               ["bytes", bytes] <- String.split(range, "=", parts: 2),
               [s_start, s_end] <- String.split(bytes, "-", parts: 2)
          do
            maybe_end = Integer.parse(s_end)

            {r_start, r_end} =
              case Integer.parse(s_start) do
                {r_start, ""} ->
                  case maybe_end do
                    {r_end, ""} -> {r_start, r_end}
                    _ -> {r_start, file.size - 1}
                  end
                _ ->
                  case maybe_end do
                    {r_end, ""} -> {file.size - r_end, file.size - 1}
                    _ -> {0, file.size - 1}
                  end
              end

            length = r_end - r_start + 1

            conn
            |> put_resp_header(
              "Content-Range", "bytes " <>
              Integer.to_string(r_start) <> "-" <>
              Integer.to_string(r_end) <> "/" <>
              Integer.to_string(file.size)
            )
            |> send_file(206, absolute_path, r_start, length)
          else
            x -> send_file(conn, 200, absolute_path)
          end
    end
  end

  def download_no_filename(conn, %{"uuid" => uuid}) do
    download(conn, %{"uuid" => uuid, "realfilename" => ""})
  end

  def check_extension(filename, extensions) do
    file_extension = filename |> Path.extname |> String.downcase
    Enum.member?(extensions, file_extension)
  end
end
