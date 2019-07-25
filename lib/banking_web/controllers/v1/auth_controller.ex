defmodule BankingWeb.V1.AuthController do
  use BankingWeb, :controller

  alias Banking.Auth

  action_fallback BankingWeb.FallbackController

  def signin(conn, params) do
    with {:ok, _, token} <- params["email"] |> Auth.authenticate_user(params["password"]) do
      conn
      |> render("auth.json", token: token)
    end
  end
end
