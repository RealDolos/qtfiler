defmodule Qtfile.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Accounts.User


  schema "users" do
    field :name, :string
    field :password, :string
    field :username, :string
    # Available statuses:
    # active - not banned
    # banned - banned
    field :status, :string, default: "active"
    # Available roles:
    # admin - runs the site
    # mod - moderates the site
    # user - regular user, no special privs
    field :role, :string, default: "user"
    field :secret, :binary
    has_many :files, Qtfile.Files.File, on_delete: :delete_all, foreign_key: :uploader

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username, :password, :status, :role, :secret])
    |> validate_required([:name, :username, :password, :status, :role, :secret])
    |> unique_constraint(:username)
    |> unique_constraint(:secret)
  end
end
