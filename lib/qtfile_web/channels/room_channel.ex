defmodule QtfileWeb.RoomChannel do
  require Logger
  use Phoenix.Channel
  alias QtfileWeb.Presence
  intercept ["files", "presence_diff", "new_files"]
  require Qtfile.Rooms

  def join("room:" <> room_id, _message, socket) do
    if Qtfile.Rooms.room_exists?(room_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "Room does not exist"}}
    end
  end

  def join(_topic, _message, _socket) do
    {:error, %{reason: "Unavailable"}}
  end

  # def handle_in("broadcast_notification", %{"title" => title, "body" => body}, socket) do
  #   IO.inspect title
  #   IO.inspect body
  #   broadcast!(socket, "notification", %{title: title, body: body})
  #   {:noreply, socket}
  # end

  defp get_user_and_room(socket) do
    "room:" <> room_id = socket.topic
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)
    user =
      case socket.assigns[:user_id] do
        {:anonymous, _} = x -> x
        {:logged_in, user_id} -> {:logged_in, Qtfile.Accounts.get_user(user_id)}
      end
    {user, room}
  end

  def handle_out_files(key, %{body: files}, socket) do
    {user, room} = get_user_and_room(socket)
    new_files = Enum.map(files, fn(file) ->
      Qtfile.IPAddressObfuscation.ip_filter(room, user, file)
    end)
    push(socket, key, %{body: new_files})
    {:noreply, socket}
  end
  
  def handle_out("files", data, socket) do
    handle_out_files("files", data, socket)
  end

  def handle_out("new_files", data, socket) do
    handle_out_files("new_files", data, socket)
  end

  def handle_out("presence_diff", diff, socket) do
    push(socket, "presence_diff", presence_filter_ips_diff(diff, socket))
    {:noreply, socket}
  end

  defp presence_filter_ips(presence_diff, socket) do
    {user, room} = get_user_and_room(socket)
    presence_diff
    |> Enum.map(fn({user_id, %{metas: metas} = data}) ->
      new_metas = Enum.map(metas,
      &(Qtfile.IPAddressObfuscation.ip_filter(room, user, &1))
    )
      {user_id, %{data | metas: new_metas}}
    end)
    |> Enum.into(%{})
  end

  defp presence_filter_ips_diff(presence_info, socket) do
    presence_info
    |> Enum.map(fn({operation_id, values}) ->
      values
      |> presence_filter_ips(socket)
      |> (&{operation_id, &1}).()
    end)
    |> Enum.into(%{})
  end

  def handle_info(:after_join, socket) do
    {user, room} = get_user_and_room(socket)
    #:timer.apply_interval(300, __MODULE__, :increment, [socket])
    files = Enum.map(Qtfile.Files.get_files_by_room_id(room.room_id),
      &(Qtfile.Files.process_for_browser/1))
    push(socket, "presence_state", presence_filter_ips(Presence.list(socket), socket))
    presence_key = inspect(socket.assigns[:user_id])
    {:ok, _} = Presence.track(socket, presence_key,
      %{
        online_at: DateTime.utc_now(),
        ip_address: socket.assigns.ip_address,
      }
    )
    {role, owner} =
      case user do
        {:anonymous, _} -> {"anon", false}
        {:logged_in, real_user} -> {real_user.role, room.owner_id == real_user.id}
      end
    push(socket, "role", %{body: role})
    push(socket, "owner", %{body: owner})
    settings = Qtfile.Rooms.get_settings_by_room_for_browser(room)
    push(socket, "settings", %{settings: settings})
    handle_out("new_files", %{body: files}, socket)
    push(socket, "preview",
      Enum.group_by(Enum.map(
        Qtfile.Files.get_previews_by_room_id(room.room_id), fn({k, v}) ->
          {k, Qtfile.Files.process_for_browser(v)}
        end
      ), fn({k, _}) -> k end, fn({_, v}) -> v end)
    )
    {:noreply, socket}
  end

  def handle_info({:deleted, room_id, file_uuid}, socket) do
    QtfileWeb.Endpoint.broadcast!("room:" <> room_id, "deleted", %{body: file_uuid})
    {:noreply, socket}
  end

  def handle_info(:update_settings, socket) do
    {user, room} = get_user_and_room(socket)
    settings = Qtfile.Rooms.get_settings_by_room_for_browser(room)
    QtfileWeb.Endpoint.broadcast!(
      "room:" <> room.room_id,
      "deleted", %{settings: settings}
    )
    {:noreply, socket}
  end

  def handle_in("delete", %{"files" => files}, socket) do
    {user, room} = get_user_and_room(socket)
    if Qtfile.Accounts.has_mod_authority(user, room) do
      results = Enum.map(files, fn(uuid) ->
        file = Qtfile.Files.get_file_by_uuid(uuid)
        if file != nil and file.location_id == room.id do
          Qtfile.Files.delete_file(file)
          broadcast_deleted_file(file)
          :ok
        else
          :error
        end
      end)
      {:reply, {:ok, %{results: results}}, socket}
    else
      {:reply, :error, socket}
    end
  end

  def handle_in("settings", %{"settings" => settings}, socket) do
    {user, room} = get_user_and_room(socket)
    if Qtfile.Accounts.has_mod_authority(user, room) do
      Enum.map(settings, fn(%{"id" => id, "value" => value}) ->
        setting = Qtfile.Rooms.get_setting_by_id(id)
        {:ok, _} = Qtfile.Rooms.update_setting(setting, %{value: inspect(value)})
      end)
      send(self(), :update_settings)
      {:reply, {:ok, %{success: true}}, socket}
    else
      {:reply, {:ok, %{success: false, error: "insufficient privileges"}}, socket}
    end
  end

  def handle_in("ban", ban, socket) do
    {user, room} = get_user_and_room(socket)
    ban_e = Qtfile.Bans.preprocess_input_for_database(user, room, ban)
    result =
      case ban_e do
        {:ok, ban} -> Qtfile.Bans.create_ban(ban)
        {:error, _} = e -> e
      end
    case result do
      {:ok, _} -> {:reply, {:ok, %{success: true}}, socket}
      {:error, e} ->
        error =
          case e do
            :insufficient_ban_permission ->
              "you do not have permission to ban with these parameters"
            :insufficient_ip_decryption_permission ->
              "you do not have permission to decrypt one of the ip addresses specified"
            :ip_decryption_failed ->
              "failed to decrypt one of the specified ip addresses"
            _ ->
              Logger.info("error creating ban: ")
              Logger.info(inspect(e))
              "unknown error, please report to an admin"
          end
        {:reply, {:ok, %{success: false, error: e}}, socket}
    end
  end

  def broadcast_new_files(files, room_id) do
    QtfileWeb.Endpoint.broadcast!("room:" <> room_id, "files", %{body: files})
  end

  def broadcast_new_metadata(metadata, file, room_id) do
    QtfileWeb.Endpoint.broadcast!(
      "room:" <> room_id, "metadata", %{file.uuid => metadata}
    )
  end

  def broadcast_new_preview(mime_type, file, room_id) do
    QtfileWeb.Endpoint.broadcast!(
      "room:" <> room_id, "preview", %{file.uuid => [%{mime_type: mime_type}]}
    )
  end

  def broadcast_deleted_file(file) do
    send(self(), {:deleted, file.location.room_id, file.uuid})
  end

  def increment(socket) do
    # number = Channelstest.Incrementer.increment()
    # IO.inspect number
    number = 1

    push(socket, "update", %{body: number})
  end
end
