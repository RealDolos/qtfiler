defmodule Qtfile.Repo.Migrations.ForeignKeyDeletes do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      modify :owner_id, references(:users, on_delete: :delete_all, on_update: :update_all)
    end
    alter table(:files) do
      modify :location_id, references(:rooms, on_delete: :delete_all, on_update: :update_all)
      modify :uploader_id, references(:users, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:metadata, "metadata_file_id_fkey")
    alter table(:metadata) do
      modify :file_id, references(:files, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:previews, "previews_file_id_fkey")
    alter table(:previews) do
      modify :file_id, references(:files, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:bans, "bans_banner_id_fkey")
    drop constraint(:bans, "bans_room_id_fkey")
    alter table(:bans) do
      modify :banner_id, references(:users, on_delete: :delete_all, on_update: :update_all)
      modify :room_id, references(:rooms, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:user_bans, "user_bans_bannee_id_fkey")
    drop constraint(:user_bans, "user_bans_ban_id_fkey")
    alter table(:user_bans) do
      modify :bannee_id, references(:users, on_delete: :delete_all, on_update: :update_all)
      modify :ban_id, references(:bans, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:file_bans, "file_bans_ban_id_fkey")
    alter table(:file_bans) do
      modify :ban_id, references(:bans, on_delete: :delete_all, on_update: :update_all)
    end
    drop constraint(:ip_bans, "ip_bans_user_ban_id_fkey")
    alter table(:ip_bans) do
      modify :user_ban_id, references(:user_bans, on_delete: :delete_all, on_update: :update_all)
    end
  end
end
