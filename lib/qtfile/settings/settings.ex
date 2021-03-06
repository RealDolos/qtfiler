defmodule Qtfile.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias Qtfile.Repo
  alias Qtfile.Settings.Setting
  use Witchcraft
  import Qtfile.Util
  alias Algae.Either.{Left, Right}

  @doc """
  Returns the list of settings.

  ## Examples

      iex> list_settings()
      [%Setting{}, ...]

  """
  def list_settings do
    Repo.all(Setting)
  end

  @doc """
  Gets a single setting.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!(123)
      %Setting{}

      iex> get_setting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_setting!(id), do: Repo.get!(Setting, id)

  @doc """
  Creates a setting.

  ## Examples

      iex> create_setting(%{field: value})
      {:ok, %Setting{}}

      iex> create_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_setting(attrs \\ %{}) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting(setting, %{field: new_value})
      {:ok, %Setting{}}

      iex> update_setting(setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Setting.

  ## Examples

      iex> delete_setting(setting)
      {:ok, %Setting{}}

      iex> delete_setting(setting)
      {:error, %Ecto.Changeset{}}

  """
  def delete_setting(%Setting{} = setting) do
    Repo.delete(setting)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{source: %Setting{}}

  """
  def change_setting(%Setting{} = setting) do
    Setting.changeset(setting, %{})
  end

  def get_setting_by_key(setting_key) do
    query = from s in Setting,
      select: s,
      where: s.key == ^setting_key

    Repo.one(query)
  end

  def get_setting_by_key!(setting_key) do
    case get_setting_by_key(setting_key) do
      nil -> raise "setting doesn't exist"
      x -> x
    end
  end

  def get_setting_value(setting_key) do
    monad Right do
      setting <- get_setting_by_key(setting_key) |> nilToEitherTag(:setting_doesnt_exist)
      convert_setting(setting) |> tagLeft(:could_not_convert_setting)
    end
  end

  def get_setting_value!(setting_key) do
    %Right{right: v} = get_setting_value(setting_key)
    v
  end
end
