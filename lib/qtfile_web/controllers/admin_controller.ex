defmodule QtfileWeb.AdminController do
  use QtfileWeb, :controller
  import Qtfile.Settings
  alias Algae.Either.{Left, Right}
  use Witchcraft
  import Qtfile.Util

  def settings(conn, _params) do
    render(conn, "settings.html")
  end

  def set_settings(conn, params) do
    params = Map.delete(params, "_csrf_token")
    result = sequence(
      Enum.map(params, fn({k, v}) ->
        get_setting_by_key(k) |> nilToEither() |> tagLeft(:setting_not_found) >>>
        fn(setting) ->
          update_setting(setting, %{value: v}) |> errToEitherTag(:could_not_update)
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
