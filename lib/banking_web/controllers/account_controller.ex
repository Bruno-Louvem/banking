defmodule BankingWeb.AccountController do
  use BankingWeb, :controller

  alias Banking.Bank
  alias Banking.Bank.Account

  action_fallback BankingWeb.FallbackController

  def index(conn, _params) do
    accounts = Bank.list_account()
    render(conn, "index.json", accounts: accounts)
  end

  def create(conn, account_params) do
    with {:ok, %Account{} = account} <- Bank.create_account(account_params) do
      conn
      |> put_status(:created)
      |> render("show.json", account: account)
    end
  end
end
