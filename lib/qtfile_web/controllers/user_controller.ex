defmodule QtfileWeb.UserController do
  use QtfileWeb, :controller
  alias Qtfile.Accounts
  alias Qtfile.Accounts.User

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_by_username_password(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: "/")
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "Wrong username or password")
        |> redirect(to: user_path(conn, :login_page))
        |> halt()
    end
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:error, :invalid_token} ->
        IO.inspect "FIRST ERROR"
        conn
        |> put_flash(:error, "Invalid registration token")
        |> redirect(to: user_path(conn, :register_page))
        |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect changeset, label: "SECOND ERROR"
        conn
        |> put_flash(:error, "failed to register an account")
        |> redirect(to: "/")
        |> halt()
      {:ok, user} ->
        Qtfile.SingleToken.delete_token_by_hash(Map.get(user_params, "token", ""))

        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> redirect(to: "/")
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
    |> halt()
  end

  def login_page(conn, _params) do
    render(conn, "login.html")
  end

  def register_page(conn, _params) do
    render(conn, "register.html")
  end
end
