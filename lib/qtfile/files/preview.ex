defmodule Qtfile.Files.Preview do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Files.File
  alias Qtfile.Files.Preview


  schema "previews" do
    belongs_to :file, File, foreign_key: :file_id
    field :mime_type, :string

    timestamps()
  end

  @doc false
  def changeset(%Preview{} = preview, attrs) do
    preview
    |> cast(
      attrs, [:mime_type]
    )
    |> validate_required([
      :mime_type,
    ])
    |> put_assoc(:file, attrs.file)
    |> unique_constraint(:file_id_mime_type)
  end
end
