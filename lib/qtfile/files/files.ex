defmodule Qtfile.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
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
      select: %{filename: f.filename, hash: f.hash, room_id: f.room_id, uuid: f.uuid, uploader: f.uploader},
      where: f.room_id == ^room_id

    Repo.all(query)
  end

  def get_file_by_uuid(uuid) do
    query = from f in File,
      select: f,
      where: f.uuid == ^uuid

    Repo.one(query)
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

  def add_file(uuid, filename, room_id, hash, size, uploader, ip_address, file_ttl) do
    create_file(%{uuid: uuid, filename: filename, extension: Path.extname(filename), room_id: room_id, hash: hash, size: size, uploader: uploader, ip_address: ip_address, file_ttl: file_ttl})

    QtfileWeb.RoomChannel.broadcast_new_files([%{filename: filename, hash: hash, room_id: room_id, uuid: uuid, size: size, uploader: uploader, ip_address: ip_address, file_ttl: file_ttl}], room_id)
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
    Repo.delete(file)
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
end
