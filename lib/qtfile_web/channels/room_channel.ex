defmodule QtfileWeb.RoomChannel do
  use Phoenix.Channel
  alias QtfileWeb.Presence
  intercept ["files", "presence_diff"]

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
    user_id = socket.assigns[:user_id]
    "room:" <> room_id = socket.topic
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)
    user = Qtfile.Accounts.get_user!(user_id)
    {user, room}
  end

  def handle_out("files", %{body: files}, socket) do
    {user, room} = get_user_and_room(socket)
    new_files = Enum.map(files, fn(file) ->
      Qtfile.IPAddressObfuscation.ip_filter(room, user, file)
    end)
    push(socket, "files", %{body: new_files})
    {:noreply, socket}
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
    {:ok, _} = Presence.track(socket, user.id,
      %{
        online_at: DateTime.utc_now(),
        ip_address: socket.assigns.ip_address,
      }
    )
    push(socket, "role", %{body: user.role})
    handle_out("files", %{body: files}, socket)
  end

  def handle_info({:deleted, room_id, file_uuid}, socket) do
    QtfileWeb.Endpoint.broadcast!("room:" <> room_id, "deleted", %{body: file_uuid})
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

  def broadcast_new_files(files, room_id) do
    files = Enum.map(files, &(Qtfile.Files.process_for_browser/1))
    QtfileWeb.Endpoint.broadcast!("room:" <> room_id, "files", %{body: files})
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
