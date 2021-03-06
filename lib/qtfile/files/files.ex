defmodule Qtfile.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Qtfile.Repo

  alias Qtfile.Files.{File, Metadata, Preview}

  @doc """
  Returns the list of files.

  ## Examples

      iex> list_files()
      [%File{}, ...]

  """
  def list_files do
    query = from f in File,
      join: r in assoc(f, :location),
      join: o in assoc(r, :owner),
      left_join: u in assoc(f, :uploader),
      left_join: m in assoc(f, :metadata),
      preload: [location: {r, owner: o}, uploader: u, metadata: m],
      select: f
    Repo.all(query)
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
      order_by: [desc: :expiration_date],
      join: o in assoc(r, :owner),
      left_join: u in assoc(f, :uploader),
      left_join: m in assoc(f, :metadata),
      preload: [location: {r, owner: o}, uploader: u, metadata: m],
      select: f
    Repo.all(query)
  end

  def get_previews_by_room_id(room_id) do
    query = from p in Preview,
      join: f in assoc(p, :file),
      join: r in assoc(f, :location),
      where: r.room_id == ^room_id,
      select: {f.uuid, p}
    Repo.all(query)
  end

  def process_for_browser(%Qtfile.Files.Preview{} = preview) do
    preview
    |> Map.from_struct()
    |> Qtfile.Util.multiDelete(
      [
        :file,
        :file_id,
        :__meta__,
      ]
    )
  end

  def process_for_browser(%Qtfile.Files.File{} = file) do
    file
    |> Repo.preload(:uploader)
    |> Map.from_struct()
    |> process_for_browser()
  end

  def process_for_browser(
    %{
      location: location,
      uploader: uploader,
      metadata: metadata,
    } = file
  ) do
    file
    |> Qtfile.Util.multiDelete(
      [
        :location_id,
        :location,
        :__meta__,
        :secret,
      ]
    )
    |> Map.put(:room_id, location.room_id)
    |> fn(file) ->
      if (uploader != nil) do
        file
        |> Map.put(:uploader, uploader.name)
        |> Map.put(:uploader_id, uploader.id)
      else
        file
        |> Map.put(:uploader, "anonymoose")
        |> Map.put(:uploader_id, -1)        
      end
    end.()
    |> Map.delete(:previews)
    |> Map.put(:metadata,
      if metadata != nil do
        metadata
        |> Map.from_struct()
        |> Qtfile.Util.multiDelete(
          [
            :file,
            :file_id,
            :__meta__,
          ]
        )
      else
        nil
      end
    )
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

  def add_preview(preview) do
    %Preview{}
    |> Preview.changeset(preview)
    |> Repo.insert()
  end

  def get_previews_by_file_type(file, type) do
    query =
      from p in Preview,
      where: p.file_id == ^file.id and p.type == ^type,
      select: p
    Repo.all(query)
  end
end
