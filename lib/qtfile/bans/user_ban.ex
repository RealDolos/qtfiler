defmodule Qtfile.Bans.UserBan do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.UserBan

  schema "user_bans" do
    belongs_to :bannee, Qtfile.Accounts.User, foreign_key: :bannee_id
    belongs_to :ban, Qtfile.Bans.Ban, foreign_key: :ban_id
    field :hell, :boolean
    has_many :ip_bans, Qtfile.Bans.IPBan, foreign_key: :user_ban_id

    timestamps()
  end

  @doc false
  def changeset(%UserBan{} = user_ban, attrs) do
    user_ban
    |> cast(attrs, [:hell])
    |> put_assoc(:ban, attrs.ban)
    |> fn(user_ban) ->
      if Map.has_key?(attrs, :bannee) do
        put_assoc(user_ban, :bannee, attrs.bannee)
      else
        user_ban
      end
    end.()
    |> put_assoc(:ip_bans, attrs.ip_bans)
    |> unique_constraint([:ban, :bannee])
    |> validate_required([:hell])
  end
end
