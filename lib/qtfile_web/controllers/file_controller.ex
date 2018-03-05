defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  require Logger
  alias Qtfile.Settings
  alias Qtfile.FileProcessing.{Storage, Hashing, UploadState}
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
    case Qtfile.Rooms.uploadable_room(room_id) do
      {:ok, room} = r ->
        case Qtfile.Bans.get_bans_for([Qtfile.Accounts.get_user!(user_id), ip_address], room) do
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
    uploader = Qtfile.Accounts.get_user!(uploader_id)
    ip_address = Qtfile.Util.get_ip_address(conn)
    %{file_ttl: file_ttl} = room
    expiration_date = DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) + file_ttl)
      
    %{
      uuid: uuid,
      filename: filename,
      mime_type: content_type,
      location: room,
      size: size,
      uploader: uploader,
      ip_address: ip_address,
      expiration_date: expiration_date,
      hash: hash,
    }
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

              case Qtfile.Files.create_file(file_data) do
                {:ok, _} ->
                  :ok = Qtfile.FileProcessing.UploadEvent.notify_upload(file_data)
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
      "room_id" => room_id,
      "filename" => filename,
    }) do
    upload_validated(conn, %{
      "room_id" => room_id,
      "filename" => filename,
      "content_type" => nil
    })
  end

  defp logged_in?(conn) do
    case get_session(conn, :user_id) do
      nil -> false
      _ -> true
    end
  end

  def download(conn, %{"uuid" => uuid, "realfilename" => _realfilename}) do
    if logged_in?(conn) or Settings.get_setting_value!("anon_download") do
      file = Qtfile.Files.get_file_by_uuid(uuid)

      if file != nil do
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

        if nice_file do
          conn
          |> put_resp_content_type(mime_type)
          |> send_file(200, absolute_path)
        else
          download_params = [filename: file.filename] ++ if file.mime_type == nil do
            []
          else
            [content_type: file.mime_type]
          end
          conn
          |> send_download({:file, absolute_path}, download_params)
        end

      else
        conn
        |> put_status(404)
        |> text("file not found!")
      end
    else
      conn
      |> send_resp(:forbidden, "Not logged in")
      |> halt()
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
