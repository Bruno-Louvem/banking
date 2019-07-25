defmodule BankingWeb.V1.TransactionController do
  use BankingWeb, :controller

  alias Banking.Bank

  action_fallback BankingWeb.FallbackController

  def deposit(conn, %{"amount" => amount}) do
    account = conn.assigns.current_user.account

    with {:ok, account, transaction} <- account |> Bank.deposit(amount) do
      conn
      |> send_transaction_response("deposit", transaction, account)
    end
  end

  def deposit(_, _), do: {:error, "Invalid amount", 442}

  def withdrawal(conn, %{"amount" => amount}) do
    account = conn.assigns.current_user.account

    with {:ok, account, transaction} <- account |> Bank.withdrawal(amount) do
      conn
      |> send_transaction_response("withdrawal", transaction, account)
    end
  end

  def transfer(conn, %{"amount" => amount, "account_id" => account_b_id}) do
    account_a = conn.assigns.current_user.account

    with {:ok, account_b} <- account_b_id |> Bank.get_account(),
         {:ok, %{transaction_a: t_a, transaction_b: t_b}} <-
           account_a |> Bank.transfer(account_b, amount) do
      conn
      |> render("transfer.json", type: "transfer", transaction_a: t_a, transaction_b: t_b)
    end
  end

  def report(conn, _params) do
    transactions = Bank.report()

    with true <- !(transactions.today |> is_nil),
         true <- !(transactions.month |> is_nil),
         true <- !(transactions.year |> is_nil) do
      conn
      |> render("report_transaction.json", transactions: transactions)
    end
  end

  def balance(conn, %{"account_id" => account_id}) do
    user_api_account = conn.assigns.current_user.account

    with true <- user_api_account.id == account_id,
         {:ok, account} <- account_id |> Bank.get_account() do
      conn |> render("balance.json", balance: account.balance.amount, account_id: account.id)
    else
      false -> {:error, "You just make transfers from your account", 403}
    end
  end

  defp send_transaction_response(conn, transaction_type, transaction, account) do
    conn
    |> render("transaction.json",
      transaction: %{
        account_id: account.id,
        amount: transaction.amount,
        transaction_id: transaction.id,
        type: transaction_type,
        date: transaction.inserted_at
      }
    )
  end
end
