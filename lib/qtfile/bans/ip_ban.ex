defmodule Qtfile.Bans.IPBan do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.IPBan

  schema "ip_bans" do
    belongs_to :user_ban, Qtfile.Bans.UserBan, foreign_key: :user_ban_id
    field :ip_address, :binary

    timestamps()
  end

  @doc false
  def changeset(%IPBan{} = ip_ban, attrs) do
    ip_ban
    |> cast(attrs, [:ip_address])
    |> put_assoc(:user_ban, attrs.user_ban)
    |> validate_required([:ip_address])
    |> unique_constraint([:user_ban, :ip_address])
  end
end
