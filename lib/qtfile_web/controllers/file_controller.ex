defmodule QtfileWeb.FileController do
  use QtfileWeb, :controller
  alias Qtfile.Settings
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

  defp save_file_loop(conn, state, write) do
    {status, data, conn} = read_body(conn,
      length: Settings.get_setting_value!("max_file_length"),
      read_length: 64 * 1024,
      read_timeout: 1024
    )
    {^status, state} = write.(state, data)
    case status do
      :more -> save_file_loop(conn, state, write)
      :ok -> {:ok, state, conn}
    end
  end

  defp upload_validated(conn,
    %{
      "room_id" => room_id,
      "filename" => filename,
      "content_type" => content_type
    }, room) do

    size = :erlang.binary_to_integer(hd(get_req_header(conn, "content-length")))
    uploader_id = get_session(conn, :user_id)
    uploader = Qtfile.Accounts.get_user!(uploader_id)
    ip_address = Qtfile.Util.get_ip_address(conn)
    %{file_ttl: file_ttl} = room
    expiration_date = DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) + file_ttl)

    file_data = %{
      uuid: Ecto.UUID.generate(),
      filename: filename,
      mime_type: content_type,
      location: room,
      size: size,
      uploader: uploader,
      ip_address: ip_address,
      expiration_date: expiration_date,
    }

    {:ok, conn} =
      Qtfile.FileProcessing.Storage.store_file(file_data, fn(state, write) ->
        save_file_loop(conn, state, write)
      end)

    json conn, %{success: true}
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
