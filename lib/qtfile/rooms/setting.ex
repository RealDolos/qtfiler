defmodule Qtfile.Rooms.Setting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Rooms.{Setting, Room}


  schema "room_settings" do
    field :name, :string
    field :key, :string
    field :value, :string
    field :type, :string
    belongs_to :room, Room, foreign_key: :room_id

    timestamps()
  end

  @doc false
  def changeset(%Setting{} = setting, attrs) do
    setting
    |> cast(attrs, [:name, :key, :value, :type])
    |> fn(setting) ->
      if Map.has_key?(attrs, :room) do
        put_assoc(setting, :room, attrs.room)
      else
        setting
      end
    end.()
    |> validate_required([:name, :key, :value, :type])
  end
end
