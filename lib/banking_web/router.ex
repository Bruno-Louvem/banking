defmodule BankingWeb.Router do
  use BankingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BankingWeb do
    pipe_through :api

    post "/accounts", AccountController, :create
    get "/accounts", AccountController, :index
  end
end
