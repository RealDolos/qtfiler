defmodule Qtfile.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Accounts.User


  schema "users" do
    field :name, :string
    field :password, :string
    field :username, :string
    # Available roles:
    # admin - runs the site
    # mod - moderates the site
    # user - regular user, no special privs
    field :role, :string, default: "user"
    field :secret, :binary
    has_many :files, Qtfile.Files.File, foreign_key: :uploader_id
    has_many :rooms, Qtfile.Rooms.Room, foreign_key: :owner_id

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username, :password, :role, :secret])
    |> validate_required([:name, :username, :password, :role, :secret])
    |> validate_inclusion(:role, ["admin", "mod", "user"])
    |> unique_constraint(:username)
    |> unique_constraint(:secret)
  end
end
