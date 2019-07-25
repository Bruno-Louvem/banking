defmodule BankingWeb.V1.TransactionView do
  use BankingWeb, :view

  alias BankingWeb.V1.TransactionView

  def render("transaction.json", %{transaction: transaction}) do
    if transaction |> Map.has_key?(:type) do
      transaction_detail(
        transaction.account_id,
        transaction.amount,
        transaction.date,
        transaction.transaction_id,
        transaction.type
      )
    else
      transaction_detail(
        transaction.account_id,
        transaction.amount,
        transaction.date,
        transaction.transaction_id
      )
    end
  end

  def render("transfer.json", %{type: type, transaction_a: t_a, transaction_b: t_b}) do
    %{
      transactions: [
        render_one(t_a |> Map.put(:type, type), TransactionView, "transaction.json"),
        render_one(t_b |> Map.put(:type, type), TransactionView, "transaction.json")
      ]
    }
  end

  def render("report_transaction.json", %{transactions: transactions}) do
    %{
      today: render_many(transactions.today, TransactionView, "transaction.json"),
      month: transactions.month |> handle_groups(),
      year: transactions.year |> handle_groups()
    }
  end

  def render("balance.json", %{balance: balance, account_id: account_id}) do
    %{
      balance: balance |> Money.to_string(),
      account_id: account_id
    }
  end

  defp handle_groups(transactions) when transactions |> is_map do
    transactions
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      acc |> Map.merge(%{k => v |> handle_groups()})
    end)
  end

  defp handle_groups(transactions) when transactions |> is_list do
    transactions
    |> render_many(TransactionView, "transaction.json")
  end

  defp transaction_detail(account_id, amount, date, transaction_id, type) do
    account_id
    |> transaction_detail(amount, date, transaction_id)
    |> Map.put(:type, type)
  end

  def transaction_detail(account_id, amount, date, transaction_id) do
    %{
      transaction_id: transaction_id,
      account_id: account_id,
      amount: amount |> Money.to_string(),
      date: date
    }
  end
end
