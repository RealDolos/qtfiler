defmodule Qtfile.Files.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File


  schema "files" do
    field :filename, :string
    field :mime_type, :string
    field :uuid, :string
    belongs_to :rooms, Qtfile.Rooms.Room, foreign_key: :location
    field :hash, :string
    field :size, :integer
    belongs_to :users, Qtfile.Accounts.User, foreign_key: :uploader
    field :ip_address, :binary
    field :expiration_date, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(attrs, [:uuid, :filename, :mime_type, :hash, :size, :ip_address, :expiration_date])
    |> put_assoc(:users, attrs.users)
    |> put_assoc(:rooms, attrs.rooms)
    |> validate_required([:uuid, :filename, :hash, :size, :ip_address, :expiration_date])
    |> unique_constraint(:uuid)
  end
end
