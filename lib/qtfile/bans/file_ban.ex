defmodule Qtfile.Bans.FileBan do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.FileBan

  schema "file_bans" do
    belongs_to :ban, Qtfile.Bans.Ban, foreign_key: :ban_id
    field :hash, :string

    timestamps()
  end

  @doc false
  def changeset(%FileBan{} = file_ban, attrs) do
    file_ban
    |> cast(attrs, [:hash])
    |> fn(file_ban) ->
      if Map.has_key?(attrs, :ban) do
        put_assoc(file_ban, :ban, attrs.ban)
      else
        file_ban
      end
    end.()
    |> validate_required([:hash])
    |> unique_constraint(:ban_hash)
  end
end
