defmodule Qtfile.Bans.Ban do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.Ban


  schema "bans" do

    timestamps()
  end

  @doc false
  def changeset(%Ban{} = ban, attrs) do
    ban
    |> cast(attrs, [])
    |> validate_required([])
  end
end
