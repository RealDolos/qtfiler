defmodule Qtfile.SingleTokenTest do
  use Qtfile.DataCase

  alias Qtfile.SingleToken

  describe "tokens" do
    alias Qtfile.SingleToken.Token

    @valid_attrs %{token: "some token"}
    @update_attrs %{token: "some updated token"}
    @invalid_attrs %{token: nil}

    def token_fixture(attrs \\ %{}) do
      {:ok, token} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SingleToken.create_token()

      token
    end

    test "list_tokens/0 returns all tokens" do
      token = token_fixture()
      assert SingleToken.list_tokens() == [token]
    end

    test "get_token!/1 returns the token with given id" do
      token = token_fixture()
      assert SingleToken.get_token!(token.id) == token
    end

    test "create_token/1 with valid data creates a token" do
      assert {:ok, %Token{} = token} = SingleToken.create_token(@valid_attrs)
      assert token.token == "some token"
    end

    test "create_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SingleToken.create_token(@invalid_attrs)
    end

    test "update_token/2 with valid data updates the token" do
      token = token_fixture()
      assert {:ok, token} = SingleToken.update_token(token, @update_attrs)
      assert %Token{} = token
      assert token.token == "some updated token"
    end

    test "update_token/2 with invalid data returns error changeset" do
      token = token_fixture()
      assert {:error, %Ecto.Changeset{}} = SingleToken.update_token(token, @invalid_attrs)
      assert token == SingleToken.get_token!(token.id)
    end

    test "delete_token/1 deletes the token" do
      token = token_fixture()
      assert {:ok, %Token{}} = SingleToken.delete_token(token)
      assert_raise Ecto.NoResultsError, fn -> SingleToken.get_token!(token.id) end
    end

    test "change_token/1 returns a token changeset" do
      token = token_fixture()
      assert %Ecto.Changeset{} = SingleToken.change_token(token)
    end
  end
end
