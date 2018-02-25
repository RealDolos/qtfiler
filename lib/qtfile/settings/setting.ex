defmodule Qtfile.Settings.Setting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Qtfile.Settings.Setting


  schema "settings" do
    field :name, :string
    field :key, :string
    field :value, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(%Setting{} = setting, attrs) do
    setting
    |> cast(attrs, [:name, :key, :value, :type])
    |> validate_required([:name, :key, :value, :type])
  end
end
