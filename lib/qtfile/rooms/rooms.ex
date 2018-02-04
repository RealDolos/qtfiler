defmodule Qtfile.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Qtfile.Repo

  alias Qtfile.Rooms.Room

  def generate_room_id() do
    generate_room_id(6)
  end

  def generate_room_id(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64(padding: false) |> String.slice(0, length)
  end

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    query = from r in Room,
      join: o in assoc(r, :owner),
      preload: [owner: o],
      select: r
    Repo.all(query)
  end

  def room_exists?(room_id) do
    not (get_room_by_room_id!(room_id) == nil)
  end

  def uploadable_room(room_id) do
    case get_room_by_room_id!(room_id) do
      %{disabled: false} = room -> {:ok, room}
      _ -> :error
    end
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  def get_room_by_room_id!(room_id) do
    query = from r in Room,
      select: r,
      where: r.room_id == ^room_id

    Repo.one(query)
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_room(room_id, owner) do
    alias Qtfile.Rooms.Room

    create_room(
      %{
        room_id: room_id,
        owner: owner,
        room_name: Room.default_room_name(),
        disabled: Room.default_disabled(),
        file_ttl: Room.default_file_ttl(),
        files: Room.default_files(),
        motd: Room.default_motd(),
        secret: :crypto.strong_rand_bytes(16),
      }
    )
  end

  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{source: %Room{}}

  """
  def change_room(%Room{} = room) do
    Room.changeset(room, %{})
  end
end
