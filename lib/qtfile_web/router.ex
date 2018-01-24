defmodule QtfileWeb.Router do
  use QtfileWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  scope "/", QtfileWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login", UserController, :login_page
    get "/register", UserController, :register_page

    scope "/" do
      pipe_through :logged_in?

      get "/new", RoomController, :create_room
      get "/rooms", RoomsController, :index
      get "/get/:uuid/:realfilename", FileController, :download
      get "/get/:uuid/", FileController, :download_no_filename
    end
  end

  scope "/r", QtfileWeb do
    pipe_through [:browser, :logged_in?]

    get "/", RoomController, :not_found
    get "/:room_id", RoomController, :index
  end

  scope "/api", QtfileWeb do
    pipe_through :api

    post "/login", UserController, :login
    post "/register", UserController, :register
    get "/logout", UserController, :logout

    scope "/" do
      pipe_through :logged_in?

      post "/upload", FileController, :upload
    end

    scope "/mod" do
      pipe_through [:logged_in?, :is_mod?]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", QtfileWeb do
  #   pipe_through :api
  # end

  defp logged_in?(conn, _) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> send_resp(:forbidden, "Not logged in")
        |> halt()
      user_id ->
        conn
    end
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
end
