defmodule QtfileWeb.RoomChannel do
  use Phoenix.Channel
  require Logger

  def join("room:" <> room_id, message, socket) do
    if Qtfile.Rooms.room_exists?(room_id) do
      send(self(), {:role, socket.assigns[:user].role})
      send(self(), {:after_join, room_id})
      {:ok, socket}
    else
      {:error, %{reason: "Room does not exist"}}
    end
  end

  def join(_topic, _message, socket) do
    {:error, %{reason: "Unavailable"}}
  end

  # def handle_in("broadcast_notification", %{"title" => title, "body" => body}, socket) do
  #   IO.inspect title
  #   IO.inspect body
  #   broadcast!(socket, "notification", %{title: title, body: body})
  #   {:noreply, socket}
  # end

  def handle_info({:after_join, room_id}, socket) do
    #:timer.apply_interval(300, __MODULE__, :increment, [socket])
    files = Qtfile.Files.get_files_by_room_id(room_id)
    push(socket, "files", %{body: files})
    {:noreply, socket}
  end

  def handle_info({:role, role}, socket) do
    push(socket, "role", %{body: role})
    {:noreply, socket}
  end

  def handle_info({:deleted, room_id, file_uuid}, socket) do
    Logger.info("sending deleted message")
    QtfileWeb.Endpoint.broadcast_from!(self(), "room:" <> room_id, "deleted", %{body: file_uuid})
    Logger.info("sending deleted message 2")
    {:noreply, socket}
  end

  def handle_in("delete", %{"files" => files}, socket) do
    results = Enum.map(files, fn(uuid) ->
      file = Qtfile.Files.get_file_by_uuid(uuid)
      if file != nil do
        Qtfile.Files.delete_file(file)
        broadcast_deleted_file(file)
        :ok
      else
        :error
      end
    end)
    {:reply, {:ok, %{results: results}}, socket}
  end

  def broadcast_new_files(files, room_id) do
    QtfileWeb.Endpoint.broadcast_from!(self(), "room:" <> room_id, "files", %{body: files})
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
