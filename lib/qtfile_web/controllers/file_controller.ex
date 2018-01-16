defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  @image_extensions ~w(.jpg .jpeg .png)

  def upload(conn, %{"file" => file} = params) when not is_list(file) do
    upload(conn, %{params | "file" => [file]})
  end

  def upload(conn, %{"room_id" => room_id, "file" => files} = params) do
    if Qtfile.Rooms.room_exists?(room_id) do
      upload_room_exists(conn, params)
    else
      json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  defp upload_room_exists(conn, %{"mime_type" => mime_type, "room_id" => room_id, "file" => files}) do
    response =
      Enum.map(files, fn(file) ->
        %{filename: filename} = file
        room = Qtfile.Rooms.get_room_by_room_id!(room_id)
        uuid = Ecto.UUID.generate()
        scope = %{room_id: room_id, uuid: uuid}

        cond do
          check_extension(filename, @image_extensions) == true ->
            Qtfile.ImageFile.store({file, scope})
            |> store_in_db(conn, uuid, room, mime_type, Qtfile.ImageFile.storage_dir(:original, {file, room}))

          true ->
            Qtfile.GenericFile.store({file, scope})
            |> store_in_db(conn, uuid, room, mime_type, Qtfile.GenericFile.storage_dir(:original, {file, room}))
        end
      end) |> hd()

    # conn
    # |> redirect(to: room_path(conn, :index, room_id))
    # json conn, %{success: true}
    json conn, response
  end

  def download(conn, %{"uuid" => uuid, "realfilename" => _realfilename}) do
    file = Qtfile.Files.get_file_by_uuid(uuid)
    path = Application.get_env(:arc, :storage_dir, "uploads/rooms")

    if file != nil do
      absolute_path = get_absolute_path(file)

      mime_type = file.mime_type

      nice_file =
        case mime_type do
          nil -> false
          _ ->
            [type, _] = String.split(file.mime_type, "/")
            Enum.member?(["audio", "video", "image"], type)
        end

      if nice_file do
        conn
        |> put_resp_content_type(file.mime_type)
        |> send_file(200, absolute_path)
      else
        conn
        |> put_resp_content_type("application/octet-stream")
        |> send_download({:file, absolute_path})
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

  defp store_in_db({:ok, filename}, conn, uuid, room, mime_type, path) do
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

    hash = Qtfile.Util.hash(:sha, file_path)
    Qtfile.Files.add_file(uuid, filename, room, hash, file_size, uploader, ip_address, expiration_date, mime_type)

    %{success: true}
  end

  defp store_in_db(_ok_filename_tuple, _conn, _uuid, _room, _upload_date, _mime_type, _path) do
    %{success: false, error: "failed to upload file", preventRetry: true}
  end

  def delete(conn, %{"uuid" => uuid}) do
    file = Qtfile.Files.get_file_by_uuid(uuid)
    if file != nil do
      absolute_path = get_absolute_path(file)
      Qtfile.Files.delete_file(file)
      File.rm(absolute_path)
      conn
      |> put_status(200)
      |> json(%{success: true})
      |> halt
    else
      conn
      |> put_status(404)
      |> json(%{success: false})
      |> halt
    end
  end

  defp get_absolute_path(file) do
    path = Application.get_env(:arc, :storage_dir, "uploads/rooms")
    path <> "/" <> Qtfile.Rooms.get_room!(file.rooms_id).room_id <> "/" <> file.uuid <> "-original" <> Path.extname(file.filename)
  end
end
