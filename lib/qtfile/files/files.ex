defmodule Qtfile.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Qtfile.Repo

  alias Qtfile.Files.File

  @doc """
  Returns the list of files.

  ## Examples

      iex> list_files()
      [%File{}, ...]

  """
  def list_files do
    Repo.all(File)
  end

  @doc """
  Gets a single file.

  Raises `Ecto.NoResultsError` if the File does not exist.

  ## Examples

      iex> get_file!(123)
      %File{}

      iex> get_file!(456)
      ** (Ecto.NoResultsError)

  """
  def get_file!(id), do: Repo.get!(File, id)

  def get_files_by_room_id(room_id) do
    query = from f in File,
      join: r in assoc(f, :rooms),
      where: r.room_id == ^room_id,
      preload: :users,
      preload: :rooms,
      select: f,
      order_by: [asc: :expiration_date]

    query
    |> Repo.all
  end

  def process_for_browser(%Qtfile.Files.File{} = file) do
    process_for_browser(Map.from_struct(file))
  end

  def process_for_browser(%{rooms: room, users: user} = file) do
    Enum.reduce(
      [:rooms_id, :users_id, :rooms, :users, :__meta__, :secret], file,
      fn (n, c) ->
        Map.delete(c, n)
      end
    )
    |> Map.put(:room_id, room.room_id)
    |> Map.put(:uploader, user.username)
  end

  def get_file_by_uuid(uuid) do
    query = from f in File,
      where: f.uuid == ^uuid,
      preload: :users,
      preload: :rooms,
      select: f

    query
    |> Repo.one
  end

  @doc """
  Creates a file.

  ## Examples

      iex> create_file(%{field: value})
      {:ok, %File{}}

      iex> create_file(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_file(attrs \\ %{}) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  def add_file(uuid, filename, room, hash, size, uploader, ip_address, expiration_date, mime_type) do
    data = %{
      uuid: uuid,
      filename: filename,
      mime_type: mime_type,
      rooms: room,
      hash: hash,
      size: size,
      users: uploader,
      ip_address: ip_address,
      expiration_date: expiration_date
    }
    result = create_file(data)
    case result do
      {:ok, _} ->
        QtfileWeb.RoomChannel.broadcast_new_files([data], room.room_id)
        :ok
      {:error, changeset} ->
        Logger.error("failed to add file to db")
        Logger.error(inspect(changeset))
        :error
    end
  end

  @doc """
  Updates a file.

  ## Examples

      iex> update_file(file, %{field: new_value})
      {:ok, %File{}}

      iex> update_file(file, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_file(%File{} = file, attrs) do
    file
    |> File.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a File.

  ## Examples

      iex> delete_file(file)
      {:ok, %File{}}

      iex> delete_file(file)
      {:error, %Ecto.Changeset{}}

  """
  def delete_file(%File{} = file) do
    absolute_path = get_absolute_path(file)
    Repo.delete(file)
    Elixir.File.rm(absolute_path)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking file changes.

  ## Examples

      iex> change_file(file)
      %Ecto.Changeset{source: %File{}}

  """
  def change_file(%File{} = file) do
    File.changeset(file, %{})
  end

  def get_absolute_path(file) do
    path = Application.get_env(:arc, :storage_dir, "uploads/rooms")
    path <> "/" <> file.rooms.room_id <> "/" <> file.uuid <> "-original" <> Path.extname(file.filename)
  end
end
