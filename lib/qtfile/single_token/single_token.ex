defmodule Qtfile.SingleToken do
  @moduledoc """
  The SingleToken context.
  """

  import Ecto.Query, warn: false
  alias Qtfile.Repo

  alias Qtfile.SingleToken.Token

  def generate_token() do
    generate_token(48)
  end

  def generate_token(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64(padding: false)
  end

  def verify_token(token) do
    query = from t in Token,
      select: t.token,
      where: t.token == ^token

    result = Repo.all(query) |> Enum.count

    result > 0
  end

  @doc """
  Returns the list of tokens.

  ## Examples

      iex> list_tokens()
      [%Token{}, ...]

  """
  def list_tokens do
    Repo.all(Token)
  end

  @doc """
  Gets a single token.

  Raises `Ecto.NoResultsError` if the Token does not exist.

  ## Examples

      iex> get_token!(123)
      %Token{}

      iex> get_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_token!(id), do: Repo.get!(Token, id)

  def get_token() do
    get_token(1)
  end

  def get_token(limit) do
    # query = from token in Token,
    #   select: token.token

    # stream = Repo.stream(query, [{:max_rows, 1}])

    # Repo.transaction(fn() ->
    #   Enum.to_list(stream)
    # end)

    query = from t in Token,
      select: %{token: t.token, id: t.id},
      limit: ^limit

    Repo.all(query)
  end

  @doc """
  Creates a token.

  ## Examples

      iex> create_token(%{field: value})
      {:ok, %Token{}}

      iex> create_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_token(attrs \\ %{}) do
    changeset = %{token: generate_token()}

    %Token{}
    |> Token.changeset(attrs)
    |> Repo.insert()

    Map.get(changeset, :token)
  end

  @doc """
  Updates a token.

  ## Examples

      iex> update_token(token, %{field: new_value})
      {:ok, %Token{}}

      iex> update_token(token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_token(%Token{} = token, attrs) do
    token
    |> Token.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Token.

  ## Examples

      iex> delete_token(token)
      {:ok, %Token{}}

      iex> delete_token(token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_token(%Token{} = token) do
    Repo.delete(token)
  end

  def delete_token_by_hash(token) do
    query = from t in Token,
      select: %{token: t.token, id: t.id},
      where: t.token == ^token

    case Repo.all(query) do
      [%{token: token, id: id}] ->
        delete_token(%Token{token: token, id: id})
      _ ->
        {:error, "lmao"}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking token changes.

  ## Examples

      iex> change_token(token)
      %Ecto.Changeset{source: %Token{}}

  """
  def change_token(%Token{} = token) do
    Token.changeset(token, %{})
  end
end
