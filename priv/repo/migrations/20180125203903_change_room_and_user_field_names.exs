defmodule Qtfile.Repo.Migrations.ChangeRoomAndUserFieldNames do
  use Ecto.Migration

  def change do
    rename table("files"), :rooms_id, to: :location
    rename table("files"), :users_id, to: :uploader
  end
end
