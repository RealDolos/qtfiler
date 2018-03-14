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
    has_one :metadata, Qtfile.Files.Metadata, foreign_key: :file_id, on_delete: :delete_all
    has_many :previews, Qtfile.Files.Preview, foreign_key: :file_id, on_delete: :delete_all
    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(
      attrs, [:uuid, :filename, :mime_type, :hash, :size, :ip_address, :expiration_date]
    )
    |> validate_required([
      :uuid,
      :filename,
      :hash,
      :size,
      :ip_address,
      :expiration_date
    ])
    |> fn(file) ->
      if Map.has_key?(attrs, :uploader) do
        put_assoc(file, :uploader, attrs.uploader)
      else
        file
      end
    end.()
    |> put_assoc(:location, attrs.location)
    |> unique_constraint(:uuid)
  end
end
