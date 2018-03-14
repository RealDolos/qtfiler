defmodule QtfileWeb.Router do
  use QtfileWeb, :router
  alias Qtfile.Settings

  pipeline :browser do
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :upload do
    plug Plug.Parsers,
      parsers: [:urlencoded],
      pass: ["*/*"]
    plug :fetch_session
    plug :fetch_flash
  end    

  scope "/", QtfileWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login", UserController, :login_page
    get "/register", UserController, :register_page

    scope "/" do
      pipe_through :logged_in_or_anon_view?

      get "/rooms", RoomsController, :index
    end

    scope "/" do
      pipe_through :logged_in_or_anon_view?

      get "/pget/:uuid", FileController, :download_preview
    end

    scope "/" do
      pipe_through :logged_in_or_anon_download?

      get "/get/:uuid/:realfilename", FileController, :download
      get "/get/:uuid/", FileController, :download_no_filename
    end

    scope "/" do
      pipe_through :logged_in?

      get "/new", RoomController, :create_room
    end
  end

  scope "/admin", QtfileWeb do
    pipe_through [:browser, :logged_in?, :is_admin?]
    get "/settings", AdminController, :settings
    post "/settings", AdminController, :set_settings
    get "/control", AdminController, :control
    post "/thumb-regen", AdminController, :thumb_regen
  end

  scope "/r", QtfileWeb do
    pipe_through [:browser, :logged_in_or_anon_view?]

    get "/", RoomController, :not_found
    get "/:room_id", RoomController, :index
  end

  scope "/api", QtfileWeb do
    scope "/" do
      pipe_through [:upload, :logged_in_or_anon_upload?]

      post "/upload", FileController, :upload
    end

    pipe_through :api

    post "/login", UserController, :login
    post "/register", UserController, :register
    get "/logout", UserController, :logout


    scope "/mod" do
      pipe_through [:logged_in?, :is_mod?]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", QtfileWeb do
  #   pipe_through :api
  # end

  defp forbidden_unless(pred, message, conn) do
    if pred do
      conn
    else
      conn
      |> send_resp(:forbidden, message)
      |> halt()
    end
  end

  defp logged_in_or(pred, conn) do
    forbidden_unless(
      case get_session(conn, :user_id) do
        nil -> false
        id ->
          case Qtfile.Accounts.get_user(id) do
            %Qtfile.Accounts.User{} -> true
            nil -> false
          end
      end or pred,
      "Not logged in",
      conn
    )
  end

  defp logged_in?(conn, _) do
    logged_in_or(false, conn)
  end

  defp logged_in_or_setting(key, conn) do
    logged_in_or(Settings.get_setting_value!(key), conn)
  end

  defp logged_in_or_anon_view?(conn, _) do
    logged_in_or_setting("anon_view", conn)
  end

  defp logged_in_or_anon_download?(conn, _) do
    logged_in_or_setting("anon_download", conn)
  end

  defp logged_in_or_anon_upload?(conn, _) do
    logged_in_or_setting("anon_upload", conn)
  end

  defp is_mod?(conn, _) do
    user = Qtfile.Accounts.get_user!(get_session(conn, :user_id))
    unless user.role == "mod" or user.role == "admin" do
      conn
      |> send_resp(:forbidden, "Insufficient privileges")
      |> halt()
    else
      conn
    end
  end

  defp is_admin?(conn, _) do
    user = Qtfile.Accounts.get_user!(get_session(conn, :user_id))
    unless user.role == "admin" do
      conn
      |> send_resp(:forbidden, "Insufficient privileges")
      |> halt()
    else
      conn
    end
  end
end
