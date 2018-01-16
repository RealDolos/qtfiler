defmodule Qtfile.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Rooms.Room


  schema "rooms" do
    field :disabled, :boolean, default: false
    # Seconds
    # 259200 is 72 hours
    field :file_ttl, :integer, default: 259200
    has_many :files, Qtfile.Files.File, on_delete: :delete_all
    field :motd, :string
    field :owner, :string
    field :room_id, :string
    field :room_name, :string, default: "New Room"

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
    |> cast(attrs, [:room_id, :room_name, :owner, :motd, :disabled, :file_ttl])
    |> validate_required([:room_id, :room_name, :owner, :disabled, :file_ttl])
    |> unique_constraint(:room_id)
  end
end
