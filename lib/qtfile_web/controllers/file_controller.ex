defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  @image_extensions ~w(.jpg .jpeg .png)

  def upload(conn, %{"room_id" => room_id, "file" => [file|t]}) do
    upload(conn, %{"room_id" => room_id, "file" => file})

    upload(conn, %{"room_id" => room_id, "file" => t})
  end

  def upload(conn, %{"room_id" => room_id, "file" => file} = params) do
    if Qtfile.Rooms.room_exists?(room_id) do
      upload_room_exists(conn, params)
    else
      json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  defp upload_room_exists(conn, %{"room_id" => room_id, "file" => file}) do
    %{filename: filename} = file
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)
    uuid = Ecto.UUID.generate()
    scope = %{room_id: room_id, uuid: uuid}

    cond do
      check_extension(filename, @image_extensions) == true ->
        Qtfile.ImageFile.store({file, scope})
        |> store_in_db(conn, room_id, uuid, Qtfile.ImageFile.storage_dir(:original, {file, room}))

      true ->
        Qtfile.GenericFile.store({file, scope})
        |> store_in_db(conn, room_id, uuid, Qtfile.GenericFile.storage_dir(:original, {file, room}))
    end

    # conn
    # |> redirect(to: room_path(conn, :index, room_id))
    # json conn, %{success: true}
  end

  def download(conn, %{"uuid" => uuid, "realfilename" => _realfilename}) do
    file = Qtfile.Files.get_file_by_uuid(uuid)
    path = Application.get_env(:arc, :storage_dir, "uploads/rooms")

    if file != nil do
      absolute_path = path <> "/" <> file.room_id <> "/" <> uuid <> "-original" <> file.extension

      send_file(conn, 200, absolute_path)
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

  defp store_in_db({:ok, filename}, conn, room_id, uuid, path) do
    file_path = Path.absname(path <> "/" <> uuid <> "-original" <> Path.extname(filename))
    file_size =
      case File.stat(file_path) do
        {:ok, %{size: size}} ->
          size
        _ ->
          0
      end

    hash = Qtfile.Util.hash(:sha, file_path)
    Qtfile.Files.add_file(uuid, filename, room_id, hash, file_size)

    json conn, %{success: true}
  end

  defp store_in_db(_ok_filename_tuple, conn, _room_id, _uuid, _path) do
    json conn, %{success: false, error: "failed to upload file", preventRetry: true}
  end
end
