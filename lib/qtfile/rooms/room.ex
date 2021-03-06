defmodule Qtfile.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Rooms.{Room, Setting}


  schema "rooms" do
    field :disabled, :boolean, default: false
    # Seconds
    # 259200 is 72 hours
    field :file_ttl, :integer, default: 259200
    has_many :files, Qtfile.Files.File, foreign_key: :location_id
    field :motd, :string
    belongs_to :owner, Qtfile.Accounts.User, foreign_key: :owner_id
    field :room_id, :string
    field :room_name, :string, default: "New Room"
    field :secret, :binary
    has_many :settings, Setting, foreign_key: :room_id, on_delete: :delete_all

    timestamps()
  end

  def default_room_name, do: "New Room"
  def default_files, do: []
  def default_motd, do: ""
  def default_file_ttl, do: 259200
  def default_disabled, do: false



  @doc false
  def changeset(%Room{} = room, attrs) do
    room
    |> cast(attrs, [:room_id, :room_name, :motd, :disabled, :file_ttl, :secret])
    |> validate_required([:room_id, :room_name, :disabled, :file_ttl, :secret])
    |> fn(room) ->
      if Map.has_key?(attrs, :owner) do
        put_assoc(room, :owner, attrs.owner)
      else
        room
      end
    end.()
    |> cast_assoc(:settings)
    |> unique_constraint(:room_id)
    |> unique_constraint(:secret)
  end
end
