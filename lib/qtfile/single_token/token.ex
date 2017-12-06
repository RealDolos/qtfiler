defmodule Qtfile.SingleToken.Token do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.SingleToken.Token


  schema "tokens" do
    field :token, :string

    timestamps()
  end

  @doc false
  def changeset(%Token{} = token, attrs) do
    token
    |> cast(attrs, [:token])
    |> validate_required([:token])
    |> unique_constraint(:token)
  end
end
