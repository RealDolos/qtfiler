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
  end

  scope "/", QtfileWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/login", UserController, :login_page
    get "/register", UserController, :register_page

  end

  scope "/api", QtfileWeb do
    pipe_through :api

    post "/login", UserController, :login
    get "/logout", UserController, :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", QtfileWeb do
  #   pipe_through :api
  # end
end
