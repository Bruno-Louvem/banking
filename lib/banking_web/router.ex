defmodule BankingWeb.Router do
  use BankingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Banking.Auth.Pipeline
  end

  # Unauthenticated routes

  scope "/api", BankingWeb do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      post "/signin", AuthController, :signin
      post "/signup", AccountController, :create
    end

    scope "/v1", V1, as: :v1 do
      pipe_through [:authenticated]

      get "/accounts", AccountController, :index

      post "/deposit", TransactionController, :deposit
      post "/transfer", TransactionController, :transfer
      post "/withdrawal", TransactionController, :withdrawal

      get "/balance/:account_id", TransactionController, :balance
      get "/report", TransactionController, :report
    end
  end
end
