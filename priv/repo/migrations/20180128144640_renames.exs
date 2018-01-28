defmodule Qtfile.Repo.Migrations.Renames do
  use Ecto.Migration

  def change do
    rename table("files"), :location, to: :location_id
    rename table("files"), :uploader, to: :uploader_id
    rename table("rooms"), :owner, to: :owner_id
  end
end
