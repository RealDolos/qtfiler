defmodule Qtfile.Files.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File


  schema "files" do
    field :filename, :string
    field :mime_type, :string
    field :uuid, :string
    belongs_to :location, Qtfile.Rooms.Room, foreign_key: :location_id
    field :hash, :string
    field :size, :integer
    belongs_to :uploader, Qtfile.Accounts.User, foreign_key: :uploader_id
    field :ip_address, :binary
    field :expiration_date, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(
      attrs, [:uuid, :filename, :mime_type, :hash, :size, :ip_address, :expiration_date]
    )
    |> put_assoc(:uploader, attrs.uploader)
    |> put_assoc(:location, attrs.location)
    |> validate_required([
      :location_id,
      :uploader_id,
      :uuid,
      :filename,
      :hash,
      :size,
      :ip_address,
      :expiration_date
    ])
    |> unique_constraint(:uuid)
  end
end
