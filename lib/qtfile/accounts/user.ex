defmodule Qtfile.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Accounts.User


  schema "users" do
    field :name, :string
    field :password, :string
    field :username, :string
    field :status, :string
    field :role, :string

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username, :password])
    |> validate_required([:name, :username, :password, :status, :role])
    |> unique_constraint(:username)
  end
end
