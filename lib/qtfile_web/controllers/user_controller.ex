defmodule QtfileWeb.UserController do
  use QtfileWeb, :controller
  alias Qtfile.Accounts
  alias Qtfile.Accounts.User

  def login(conn, %{"username" => username, "password" => password}) do
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

  def register(conn, %{"name" => name, "username" => username, "password" => password}) do
    case Accounts.create_user(%{name: name, username: username, password: password, token: token}) do
      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Invalid registration token")
        |> redirect(to: user_path(conn, :register_page))
        |> halt()
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
