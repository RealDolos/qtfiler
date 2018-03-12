defmodule QtfileWeb.RoomsController do
  use QtfileWeb, :controller
  alias Qtfile.Accounts.User
  alias Qtfile.Settings

  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    logged_in =
      case user_id do
        nil -> false
        _ ->
          case Qtfile.Accounts.get_user(user_id) do
            %User{} -> true
            nil -> false
          end
      end

    allowed = logged_in or Settings.get_setting_value!("anon_view")

    case allowed do
      true -> render(conn, "index.html", logged_in: logged_in)
      false ->
        conn
        |> send_resp(:forbidden, "Not logged in")
        |> halt()
    end
  end
end
