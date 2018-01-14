defmodule Qtfile.Files.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File


  schema "files" do
    field :filename, :string
    field :extension, :string
    field :uuid, :string
    field :room_id, :string
    field :hash, :string
    field :size, :integer
    field :uploader, :string
    field :ip_address, :string

    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(attrs, [:uuid, :filename, :extension, :room_id, :hash, :size, :uploader, :ip_address])
    |> validate_required([:uuid, :filename, :extension, :room_id, :hash, :size, :uploader, :ip_address])
    |> unique_constraint(:uuid)
  end
end
