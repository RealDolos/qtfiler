defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  @image_extensions ~w(.jpg .jpeg .gif .png)

  def upload(conn, %{"room_id" => room_id, "qqfile" => file} = params) do
    if Qtfile.Rooms.room_exists?(room_id) do
      upload_room_exists(conn, params)
    else
      json conn, %{success: false, error: "room does not exist", preventRetry: true}
    end
  end

  defp upload_room_exists(conn, %{"room_id" => room_id, "qqfile" => file}) do
    %{filename: filename} = file
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)

    cond do
      check_extension(filename, @image_extensions) == true ->
        Qtfile.ImageFile.store({file, room})
        |> store_in_db(room_id)

      true ->
        Qtfile.GenericFile.store({file, room})
        |> store_in_db(room_id)
    end

    # conn
    # |> redirect(to: room_path(conn, :index, room_id))
    json conn, %{success: true}
  end

  def upload(conn, _) do
    json conn, %{success: false, error: "failed to provide room id in request", preventRetry: true}
  end

  def check_extension(filename, extensions) do
    file_extension = filename |> Path.extname |> String.downcase
    Enum.member?(extensions, file_extension)
  end

  defp store_in_db({:ok, filename}, room_id) do
    uuid = Ecto.UUID.generate()
    Qtfile.Files.add_file(uuid, filename, room_id)
  end
end
