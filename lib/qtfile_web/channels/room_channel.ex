defmodule QtfileWeb.RoomChannel do
  use Phoenix.Channel
  intercept ["files"]

  def join("room:" <> room_id, _message, socket) do
    if Qtfile.Rooms.room_exists?(room_id) do
      send(self(), {:role, socket.assigns[:user].role})
      send(self(), {:after_join, room_id})
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

  def handle_out("files", %{body: files}, socket) do
    user = socket.assigns[:user]
    "room:" <> room_id = socket.topic
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)
    new_files = Enum.map(files, fn(file) ->
      Qtfile.IPAddressObfuscation.ip_filter(room, user, file)
    end)
    push(socket, "files", %{body: new_files})
    {:noreply, socket}
  end

  def handle_info({:after_join, room_id}, socket) do
    #:timer.apply_interval(300, __MODULE__, :increment, [socket])
    files = Enum.map(Qtfile.Rooms.get_files(room_id),
      &(Qtfile.Files.process_for_browser/1))
    handle_out("files", %{body: files}, socket)
  end

  def handle_info({:role, role}, socket) do
    push(socket, "role", %{body: role})
    {:noreply, socket}
  end

  def handle_info({:deleted, room_id, file_uuid}, socket) do
    QtfileWeb.Endpoint.broadcast!("room:" <> room_id, "deleted", %{body: file_uuid})
    {:noreply, socket}
  end

  def handle_in("delete", %{"files" => files}, socket) do
    user = socket.assigns[:user]
    "room:" <> room_id = socket.topic
    room = Qtfile.Rooms.get_room_by_room_id!(room_id)
    if Qtfile.Accounts.has_mod_authority(user, room) do
      results = Enum.map(files, fn(uuid) ->
        file = Qtfile.Files.get_file_by_uuid(uuid)
        if file != nil and file.location == room.id do
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
    send(self(), {:deleted, file.rooms.room_id, file.uuid})
  end

  def increment(socket) do
    # number = Channelstest.Incrementer.increment()
    # IO.inspect number
    number = 1

    push(socket, "update", %{body: number})
  end
end
