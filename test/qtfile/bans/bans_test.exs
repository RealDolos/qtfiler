defmodule Qtfile.BansTest do
  use Qtfile.DataCase

  alias Qtfile.Bans

  describe "bans" do
    alias Qtfile.Bans.Ban

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def ban_fixture(attrs \\ %{}) do
      {:ok, ban} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Bans.create_ban()

      ban
    end

    test "list_bans/0 returns all bans" do
      ban = ban_fixture()
      assert Bans.list_bans() == [ban]
    end

    test "get_ban!/1 returns the ban with given id" do
      ban = ban_fixture()
      assert Bans.get_ban!(ban.id) == ban
    end

    test "create_ban/1 with valid data creates a ban" do
      assert {:ok, %Ban{} = ban} = Bans.create_ban(@valid_attrs)
    end

    test "create_ban/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bans.create_ban(@invalid_attrs)
    end

    test "update_ban/2 with valid data updates the ban" do
      ban = ban_fixture()
      assert {:ok, ban} = Bans.update_ban(ban, @update_attrs)
      assert %Ban{} = ban
    end

    test "update_ban/2 with invalid data returns error changeset" do
      ban = ban_fixture()
      assert {:error, %Ecto.Changeset{}} = Bans.update_ban(ban, @invalid_attrs)
      assert ban == Bans.get_ban!(ban.id)
    end

    test "delete_ban/1 deletes the ban" do
      ban = ban_fixture()
      assert {:ok, %Ban{}} = Bans.delete_ban(ban)
      assert_raise Ecto.NoResultsError, fn -> Bans.get_ban!(ban.id) end
    end

    test "change_ban/1 returns a ban changeset" do
      ban = ban_fixture()
      assert %Ecto.Changeset{} = Bans.change_ban(ban)
    end
  end
end
