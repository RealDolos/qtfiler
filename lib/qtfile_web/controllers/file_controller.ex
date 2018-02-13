defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  @image_extensions ~w(.jpg .jpeg .png)
  @nice_mime_types ~w(text audio video image)

  def upload(conn, %{"room_id" => room_id} = params) do
    uploader_id = get_session(conn, :user_id)
    ip_address = Qtfile.Util.get_ip_address(conn)

    if validate_upload(room_id, uploader_id, ip_address) do
      upload_validated(conn, params)
    else
      json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  defp validate_upload(room_id, user_id, ip_address) do
    case Qtfile.Rooms.uploadable_room(room_id) do
      {:ok, room} ->
        case Qtfile.Bans.get_bans_for([Qtfile.Accounts.get_user!(user_id), ip_address], room) do
          [] -> true
          _ -> false
        end
      :error -> false
    end
  end

  defp save_file(conn, size) do
    hash = :crypto.hash_init(:sha)
    path = "uploads-temp/" <> Ecto.UUID.generate()
    {:ok, file} = :file.open(path, [:write, :binary])
    {:ok, _} = :file.position(file, size)
    :ok = :file.truncate(file)
    {:ok, _} = :file.position(file, 0)
    {conn, result} = save_file_loop(conn, file, size, hash)
    result =
      case result do
        {:ok, hash} -> {:ok, path, hash}
        x -> x
      end
    {conn, result}
  end

  defp save_file_loop(conn, _file, 0, _hash) do
    {conn, {:error, :file_too_big}}
  end

  defp save_file_loop(conn, file, size, hash) do
    result = read_body(conn,
      length: Application.get_env(:qtfile, QtfileWeb.Endpoint, :max_file_length),
      read_length: 64 * 1024,
      read_timeout: 1024
    )
    case result do
      {:error, e} -> {conn, {:error, e}}
      {status, data, conn} ->
        len = :erlang.byte_size(data)
        :ok = :file.write(file, data)
        hash = :crypto.hash_update(hash, data)
        case status do
          :ok ->
            :file.sync(file)
            :file.close(file)
            {conn, {:ok, Base.encode16(:crypto.hash_final(hash), case: :lower)}}
          :more -> save_file_loop(conn, file, size - len, hash)
        end
    end
  end

  defp upload_validated(conn,
    %{
      "room_id" => room_id,
      "filename" => filename,
      "content_type" => content_type
    }) do
    size = :erlang.binary_to_integer(hd(get_req_header(conn, "content-length")))
    {conn, save_result} = save_file(conn, size)
    response =
      case save_result do
        {:ok, path, hash} ->
          file = %Plug.Upload{path: path, content_type: content_type, filename: filename}
          room = Qtfile.Rooms.get_room_by_room_id!(room_id)
          uuid = Ecto.UUID.generate()
          scope = %{room_id: room_id, uuid: uuid}

          cond do
            check_extension(filename, @image_extensions) == true ->
              Qtfile.ImageFile.store({file, scope})
              |> store_in_db(conn, uuid, room, content_type, hash,
                Qtfile.ImageFile.storage_dir(:original, {file, room}))

            true ->
              Qtfile.GenericFile.store({file, scope})
              |> store_in_db(conn, uuid, room, content_type, hash,
                Qtfile.GenericFile.storage_dir(:original, {file, room}))
          end
        {:error, e} -> %{success: false, error: e}
      end

    # conn
    # |> redirect(to: room_path(conn, :index, room_id))
    # json conn, %{success: true}
    json conn, response
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

  def download(conn, %{"uuid" => uuid, "realfilename" => _realfilename}) do
    file = Qtfile.Files.get_file_by_uuid(uuid)
    path = Application.get_env(:arc, :storage_dir, "uploads/rooms")

    if file != nil do
      absolute_path = Qtfile.Files.get_absolute_path(file)

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
  end

  def download_no_filename(conn, %{"uuid" => uuid}) do
    download(conn, %{"uuid" => uuid, "realfilename" => ""})
  end

  def check_extension(filename, extensions) do
    file_extension = filename |> Path.extname |> String.downcase
    Enum.member?(extensions, file_extension)
  end

  defp store_in_db({:ok, filename}, conn, uuid, room, mime_type, hash, path) do
    file_path = Path.absname(path <> "/" <> uuid <> "-original" <> Path.extname(filename))
    file_size =
      case File.stat(file_path) do
        {:ok, %{size: size}} ->
          size
        _ ->
          0
      end
    uploader_id = get_session(conn, :user_id)
    uploader = Qtfile.Accounts.get_user!(uploader_id)
    ip_address = Qtfile.Util.get_ip_address(conn)
    %{file_ttl: file_ttl} = room
    expiration_date = DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) + file_ttl)

    Qtfile.Files.add_file(uuid, filename, room, hash, file_size, uploader, ip_address, expiration_date, mime_type)

    %{success: true}
  end

  defp store_in_db(_ok_filename_tuple, _conn, _uuid, _room, _upload_date, _mime_type, _path) do
    %{success: false, error: "failed to upload file", preventRetry: true}
  end
end
