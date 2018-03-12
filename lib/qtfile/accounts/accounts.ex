defmodule Qtfile.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Qtfile.Repo

  alias Qtfile.Accounts.User
  alias Qtfile.SingleToken

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_username(username) do
    query = from u in User,
      select: u,
      where: u.username == ^username

    Repo.one(query)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    IO.inspect attrs
    case SingleToken.verify_token(Map.get(attrs, "token", "")) do
      true ->
        # attrs = Map.put(attrs, "password", Bcrypt.hash_pwd_salt(Map.get(attrs, "password")))
        attrs = if Mix.env == :prod do
          Map.put(attrs, "password", Bcrypt.hash_pwd_salt(Map.get(attrs, "password")))
        else
          Map.put(attrs, "password", Map.get(attrs, "password"))
        end
        |> Map.put("role", "user")
        |> Map.put("secret", :crypto.strong_rand_bytes(16))

        %User{}
        |> User.changeset(attrs)
        # |> Ecto.Changeset.cast_assoc(:credential, with: &Credential.changeset/2)
        # |> Ecto.Changeset.cast_assoc(:token, with: &TokenHash.changeset/2)
        |> Repo.insert()
      false ->
        {:error, :invalid_token}
    end

  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def authenticate_by_username_password(username, password) do
    username = String.downcase(username)

    query =
      from u in User,
      select: %{hashed_password: u.password, user: u},
      where: fragment("lower(?)", u.username) == type(^username, :string)

    case Repo.one(query) do
      %{hashed_password: hashed_password, user: user} ->
        authenticate_by_username_password_helper(%{hashed_password: hashed_password, user: user}, password)
      nil ->
        {:error, :unauthorized}
    end
  end

  def has_mod_authority(user, room) do
    user.role == "mod" or user.role == "admin" or (room != nil and user.id == room.owner_id)
  end

  defp authenticate_by_username_password_helper(%{hashed_password: hashed_password, user: user}, password) do
    if Mix.env == :prod do
      cond do
        Bcrypt.verify_pass(password, hashed_password) ->
          {:ok, user}
        true ->
          {:error, :unauthorized}
      end
    else
      cond do
        password == hashed_password ->
          {:ok, user}
        true ->
          {:error, :unauthorized}
      end
    end
  end
end
