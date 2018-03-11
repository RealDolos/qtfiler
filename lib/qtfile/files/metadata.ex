defmodule Qtfile.Files.Metadata do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File
  alias Qtfile.Files.Metadata


  schema "metadata" do
    belongs_to :file, File, foreign_key: :file_id
    field :data, :map

    timestamps()
  end

  @doc false
  def changeset(%Metadata{} = metadata, attrs) do
    metadata
    |> cast(
      attrs, [:data]
    )
    |> validate_required([
      :data,
    ])
    |> put_assoc(:file, attrs.file)
    |> unique_constraint(:file_id)
  end
end
