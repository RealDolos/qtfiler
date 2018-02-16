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

  def defaultBan() do
    %{
      "reason" => "No reason given",
      "user_bans" => [],
      "file_bans" => [],
      "global" => false,
      "end" => 0,
    }
  end

  def preprocess_input_for_database(user, room, ban) do
    ban = Map.merge(ban, defaultBan(), fn(_, v1, _) -> v1 end)
    ban_room = if ban["global"] do nil else room end
    can_ban = Qtfile.Accounts.has_mod_authority(user, ban_room)
    if can_ban do
      processed_user_bans_e =
        Qtfile.Util.mapSequence(ban["user_bans"], fn(user_ban) ->
          processed_ip_bans_e =
            Qtfile.Util.mapSequence(user_ban["ip_bans"], fn(ip_ban) ->
              processed_ip_address_e =
                Qtfile.IPAddressObfuscation.ban_filter(room, user, ip_ban["ip_address"])
              case processed_ip_address_e do
                {:ok, processed_ip_address} ->
                  {:ok, %{ip_address: processed_ip_address}}
                {:error, _} = e -> e
              end
            end)
          case processed_ip_bans_e do
            {:ok, processed_ip_bans} ->
              {:ok, %{ip_bans: processed_ip_bans, hell: user_ban["hell"]}}
            {:error, _} = e -> e
          end
        end)
      processed_file_bans =
        Enum.map(ban["file_bans"], fn(file_ban) ->
          %{hash: file_ban["hash"]}
        end)
      processed_ban_e =
        case processed_user_bans_e do
          {:ok, processed_user_bans} ->
            ban =
              ban
              |> Map.put(:user_bans, processed_user_bans)
              |> Map.delete("user_bans")
              |> Map.put(:file_bans, processed_file_bans)
              |> Map.delete("file_bans")
              |> Map.put(:reason, ban["reason"])
              |> Map.delete("reason")
              |> Map.put(:end, DateTime.from_unix!(ban["end"]))
              |> Map.delete("end")
              |> Map.put(:banner, user)
              |> Map.put(:room, ban_room)
              |> Map.delete("global")
            {:ok, ban}
          {:error, _} = e -> e
        end
      processed_ban_e
    else
      {:error, :insufficient_ban_permission}
    end
  end
end
