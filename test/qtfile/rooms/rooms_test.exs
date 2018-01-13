defmodule Qtfile.RoomsTest do
  use Qtfile.DataCase

  alias Qtfile.Rooms

  describe "rooms" do
    alias Qtfile.Rooms.Room

    @valid_attrs %{disabled: true, file_ttl: 42, files: "some files", motd: "some motd", owner: "some owner", room_id: "some room_id", room_name: "some room_name"}
    @update_attrs %{disabled: false, file_ttl: 43, files: "some updated files", motd: "some updated motd", owner: "some updated owner", room_id: "some updated room_id", room_name: "some updated room_name"}
    @invalid_attrs %{disabled: nil, file_ttl: nil, files: nil, motd: nil, owner: nil, room_id: nil, room_name: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rooms.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Rooms.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Rooms.create_room(@valid_attrs)
      assert room.disabled == true
      assert room.file_ttl == 42
      assert room.files == "some files"
      assert room.motd == "some motd"
      assert room.owner == "some owner"
      assert room.room_id == "some room_id"
      assert room.room_name == "some room_name"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, room} = Rooms.update_room(room, @update_attrs)
      assert %Room{} = room
      assert room.disabled == false
      assert room.file_ttl == 43
      assert room.files == "some updated files"
      assert room.motd == "some updated motd"
      assert room.owner == "some updated owner"
      assert room.room_id == "some updated room_id"
      assert room.room_name == "some updated room_name"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room(room, @invalid_attrs)
      assert room == Rooms.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Rooms.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room(room)
    end
  end
end
