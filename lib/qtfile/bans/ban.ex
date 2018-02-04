defmodule Qtfile.Bans.Ban do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Bans.Ban


  schema "bans" do
    belongs_to :banner, Qtfile.Accounts.User, foreign_key: :banner_id
    belongs_to :room, Qtfile.Rooms.Room, foreign_key: :room_id
    field :end, :utc_datetime
    field :reason, :string
    has_many :user_bans, Qtfile.Bans.UserBan, foreign_key: :ban_id
    has_many :file_bans, Qtfile.Bans.FileBan, foreign_key: :ban_id

    timestamps()
  end

  @doc false
  def changeset(%Ban{} = ban, attrs) do
    ban
    |> cast(attrs, [:end, :reason])
    |> put_assoc(:banner, attrs.banner)
    |> fn(ban) ->
      if Map.has_key?(attrs, :room) do
        put_assoc(ban, :room, attrs.room)
      else
        ban
      end
    end.()
    |> put_assoc(:user_bans, attrs.user_bans)
    |> put_assoc(:file_bans, attrs.file_bans)
    |> validate_required([:end, :reason])
  end
end
