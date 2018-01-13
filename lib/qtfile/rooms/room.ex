defmodule Qtfile.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Rooms.Room


  schema "rooms" do
    field :disabled, :boolean, default: false
    field :file_ttl, :integer, default: 72
    field :files, {:array, :map}, default: []
    field :motd, :string
    field :owner, :string
    field :room_id, :string
    field :room_name, :string, default: "New Room"

    timestamps()
  end

  def default_room_name, do: "New Room"
  def default_files, do: []
  def default_motd, do: ""
  def default_file_ttl, do: 72
  def default_disabled, do: false



  @doc false
  def changeset(%Room{} = room, attrs) do
    room
    |> cast(attrs, [:room_id, :room_name, :owner, :files, :motd, :disabled, :file_ttl])
    |> validate_required([:room_id, :room_name, :owner, :files, :disabled, :file_ttl])
    |> unique_constraint(:room_id)
  end
end
