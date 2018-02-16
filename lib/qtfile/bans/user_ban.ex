defmodule Qtfile.Bans.UserBan do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.UserBan
  alias Qtfile.Repo

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
    |> fn(user_ban) ->
      if Map.has_key?(attrs, :ban) do
        put_assoc(user_ban, :ban, attrs.ban)
      else
        user_ban
      end
    end.()
    |> fn(user_ban) ->
      if Map.has_key?(attrs, :bannee_id) do
        cast(user_ban, attrs, [:bannee_id])
      else
        user_ban
      end
    end.()
    |> fn(user_ban) ->
      if Map.has_key?(attrs, :bannee) do
        put_assoc(user_ban, :bannee, attrs.bannee)
      else
        user_ban
      end
    end.()
    |> fn(user_ban) ->
      if Map.has_key?(attrs, :ip_bans) do
        cast_assoc(user_ban, :ip_bans)
      else
        user_ban
      end
    end.()
    |> unique_constraint(:ban_id_bannee_id)
    |> validate_required([:hell])
  end
end
