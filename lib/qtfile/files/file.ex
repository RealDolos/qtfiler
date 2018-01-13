defmodule Qtfile.Files.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File


  schema "files" do
    field :filename, :string
    field :uuid, :string
    field :room_id, :string
    field :size, :integer
    field :hash, :string

    timestamps()
  end

  @doc false
  def changeset(%File{} = file, attrs) do
    file
    |> cast(attrs, [:uuid, :filename, :room_id])
    |> validate_required([:uuid, :filename, :room_id])
    |> unique_constraint(:uuid)
  end
end
