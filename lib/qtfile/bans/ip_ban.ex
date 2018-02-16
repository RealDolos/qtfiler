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
    |> fn(ip_ban) ->
      if Map.has_key?(attrs, :user_ban) do
        put_assoc(ip_ban, :user_ban, attrs.user_ban)
      else
        ip_ban
      end
    end.()
    |> validate_required([:ip_address])
    |> unique_constraint(:user_ban_id_ip_address)
  end
end
