defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  @image_extensions ~w(.jpg .jpeg .gif .png)

  def upload(conn, %{"room_id" => room_id, "file" => file} = params) do
    if Qtfile.Rooms.room_exists?(room_id) do
      upload_room_exists(conn, params)
    else
      json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  defp upload_room_exists(conn, %{"room_id" => room_id, "file" => file}) do
    %{filename: filename} = file
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)

    cond do
      check_extension(filename, @image_extensions) == true ->
        Qtfile.ImageFile.store({file, room})
        |> store_in_db(conn, room_id, Qtfile.ImageFile.storage_dir(:original, {file, room}))

      true ->
        Qtfile.GenericFile.store({file, room})
        |> store_in_db(conn, room_id, Qtfile.GenericFile.storage_dir(:original, {file, room}))
    end

    # conn
    # |> redirect(to: room_path(conn, :index, room_id))
    # json conn, %{success: true}
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  def check_extension(filename, extensions) do
    file_extension = filename |> Path.extname |> String.downcase
    Enum.member?(extensions, file_extension)
  end

  defp store_in_db({:ok, filename}, conn, room_id, path) do
    uuid = Ecto.UUID.generate()
    hash = :crypto.hash(:sha, path <> filename)
    Qtfile.Files.add_file(uuid, filename, room_id, hash)

    json conn, %{success: true}
  end

  defp store_in_db(_, conn, _, _) do
    json conn, %{success: false, error: "failed to upload file", preventRetry: true}
  end
end
