defmodule Qtfile.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Qtfile.Repo

  alias Qtfile.Files.{File, Metadata}

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
      join: r in assoc(f, :location),
      where: r.room_id == ^room_id,
      order_by: [asc: :expiration_date],
      join: o in assoc(r, :owner),
      join: u in assoc(f, :uploader),
      preload: [location: {r, owner: o}, uploader: u],
      select: f
    Repo.all(query)
  end

  def process_for_browser(%Qtfile.Files.File{} = file) do
    process_for_browser(Map.from_struct(file))
  end

  def process_for_browser(%{location: location, uploader: uploader} = file) do
    file
    |> Qtfile.Util.multiDelete(
      [:location_id, :uploader_id, :location, :uploader, :__meta__, :secret]
    )
    |> Map.put(:room_id, location.room_id)
    |> Map.put(:uploader, uploader.name)
    |> Map.put(:uploader_id, uploader.id)
  end

  def get_file_by_uuid(uuid) do
    query = from f in File,
      where: f.uuid == ^uuid,
      preload: [:uploader, location: [:owner]],
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
    absolute_path = "uploads/" <> file.uuid
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

  def add_metadata(%File{} = file, metadata_object) do
    %Metadata{}
    |> Metadata.changeset(%{file: file, data: metadata_object})
    |> Repo.insert()
  end
end
