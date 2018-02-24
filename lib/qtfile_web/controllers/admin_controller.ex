defmodule QtfileWeb.AdminController do
  use QtfileWeb, :controller
  import Qtfile.Settings
  import Qtfile.Util
  use Witchcraft
  alias Algae.Either
  alias Either.{Left, Right}
  import Either

  def settings(conn, _params) do
    render(conn, "settings.html")
  end

  def set_settings(conn, params) do
    result = sequence(
      Enum.map(params, fn({k, v}) ->
        monad Right do
          setting <- get_setting_by_key(k) |> nilToEither() |> tagLeft(:setting_not_found)
          _ <- update_setting(setting, %{value: v}) |> errToEitherTag(:could_not_update)
          return nil
        end
      end)
    )
    response_code =
      case result do
        %Right{} -> :created
        _ -> :bad_request
      end
    conn
    |> put_status(response_code)
    |> render("settings.html")
  end
end
