defmodule Qtfile.Bans do
  @moduledoc """
  The Bans context.
  """

  import Ecto.Query, warn: false
  alias Qtfile.Repo

  alias Qtfile.Bans.Ban
  alias Qtfile.Bans.UserBan
  alias Qtfile.Bans.IPBan
  alias Qtfile.Bans.FileBan
  alias Qtfile.Accounts.User
  alias Qtfile.Rooms.Room
  alias Qtfile.Files.File

  @doc """
  Returns the list of bans.

  ## Examples

      iex> list_bans()
      [%Ban{}, ...]

  """
  def list_bans do
    Repo.all(Ban)
  end

  @doc """
  Gets a single ban.

  Raises `Ecto.NoResultsError` if the Ban does not exist.

  ## Examples

      iex> get_ban!(123)
      %Ban{}

      iex> get_ban!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ban!(id), do: Repo.get!(Ban, id)

  @doc """
  Creates a ban.

  ## Examples

      iex> create_ban(%{field: value})
      {:ok, %Ban{}}

      iex> create_ban(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ban(attrs \\ %{}) do
    %Ban{}
    |> Ban.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ban.

  ## Examples

      iex> update_ban(ban, %{field: new_value})
      {:ok, %Ban{}}

      iex> update_ban(ban, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ban(%Ban{} = ban, attrs) do
    ban
    |> Ban.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Ban.

  ## Examples

      iex> delete_ban(ban)
      {:ok, %Ban{}}

      iex> delete_ban(ban)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ban(%Ban{} = ban) do
    Repo.delete(ban)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ban changes.

  ## Examples

      iex> change_ban(ban)
      %Ecto.Changeset{source: %Ban{}}

  """
  def change_ban(%Ban{} = ban) do
    Ban.changeset(ban, %{})
  end

  def get_bans_for(%User{} = user, %Room{} = room) do
    query = from user_ban in UserBan,
      where: user_ban.bannee_id == ^user.id,
      join: ban in assoc(user_ban, :ban),
      preload: [ban: ban],
      where: is_nil(ban.room_id) or ban.room_id == ^room.id,
      select: user_ban
    Repo.all(query)
  end

  def get_bans_for(%File{} = file, %Room{} = room) do
    query = from file_ban in FileBan,
      where: file_ban.hash == ^file.hash,
      join: ban in assoc(file_ban, :ban),
      preload: [ban: ban],
      where: is_nil(ban.room_id) or ban.room_id == ^room.id,
      select: file_ban
    Repo.all(query)
  end

  def get_bans_for(ip_address, %Room{} = room)
  when is_binary(ip_address) do
    query = from ip_ban in IPBan,
      where: ip_ban.ip_address == ^ip_address,
      join: user_ban in assoc(ip_ban, :user_ban),
      join: ban in assoc(user_ban, :ban),
      preload: [user_ban: {user_ban, ban: ban}],
      where: is_nil(ban.room_id) or ban.room_id == ^room.id,
      select: ip_ban
    Repo.all(query)
  end

  def get_bans_for(stuff, %Room{} = room)
  when is_list(stuff) do
    Enum.flat_map(stuff, &get_bans_for(&1, room))
  end
end
