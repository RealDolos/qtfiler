defmodule Qtfile.Files.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File


  schema "files" do
    field :filename, :string
    field :mime_type, :string
    field :uuid, :string
    belongs_to :rooms, Qtfile.Rooms.Room
    field :hash, :string
    field :size, :integer
    belongs_to :users, Qtfile.Accounts.User
    field :ip_address, :string
    field :file_ttl, :integer # seconds
    field :upload_date, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(attrs, [:uuid, :filename, :mime_type, :hash, :size, :ip_address, :file_ttl, :upload_date])
    |> put_assoc(:users, attrs.uploader)
    |> put_assoc(:rooms, attrs.room)
    |> validate_required([:uuid, :filename, :mime_type, :hash, :size, :ip_address, :file_ttl, :upload_date])
    |> unique_constraint(:uuid)
  end
end
