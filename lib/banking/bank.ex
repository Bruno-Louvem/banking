defmodule Banking.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias Banking.Auth
  alias Banking.Repo
  alias Banking.Bank.{Account, Balance, Query, Transaction}

  @inital_deposit_amount Money.new(100_000)

  @doc """
  Returns the list of account.

  ## Examples

      iex> list_account()
      [%Account{}, ...]

  """
  def list_account do
    Query.list_accounts_preloaded()
    |> Repo.all()
  end

  @doc """
  Returns the list of account.

  ## Examples

      iex> get_account(account_id)
      %Account{}

  """
  def get_account(account_id) do
    Account
    |> Repo.get(account_id)
    |> Repo.preload(:balance)
    |> format_response()
  end

  defp format_response(%Account{} = account), do: {:ok, account}
  defp format_response(_), do: {:error, "Account not found", 404}

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create a user and account .

  ## Examples

      iex> list_account()
      [%Account{}, ...]

  """
  @spec signup(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) :: any
  def signup(signup_attrs) do
    with {:ok, user} <- signup_attrs |> Auth.create_user(),
         {:ok, account} <- signup_attrs |> Map.merge(%{"user_id" => user.id}) |> create_account(),
         {:ok, _} <- %{account_id: account.id} |> create_balance() do
      {:ok, account, _} = account |> deposit(@inital_deposit_amount)
      {:ok, account}
    end
  end

  @spec deposit(Banking.Bank.Account.t(), any) :: nil
  def deposit(%Account{id: account_id} = account, %Money{} = amount) do
    transaction_attrs = %{account_id: account_id, amount: amount}

    with {:ok, transaction} <- transaction_attrs |> create_transaction(),
         %Balance{} = balance <- account_id |> get_balance(),
         {:ok, _} <- balance |> update_balance(transaction.amount) do
      account =
        account
        |> Repo.preload(:balance, force: true)
        |> Repo.preload(:user, force: true)

      {:ok, account, transaction}
    end
  end

  def deposit(%Account{} = account, amount) when is_integer(amount) do
    account
    |> deposit(amount |> Money.new())
  end

  def deposit(_, _), do: {:error, "Invalid account to be accredited"}

  @spec create_transaction(
          :invalid
          | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_balance(any) :: any
  def get_balance(account_id) do
    Balance
    |> Repo.get_by(account_id: account_id)
  end

  defp create_balance(attrs) do
    attrs = attrs |> Map.merge(%{amount: 0})

    %Balance{}
    |> Balance.changeset(attrs)
    |> Repo.insert()
  end

  defp validate_balance_change(%Balance{} = balance, amount) do
    balance.amount
    |> Money.add(amount)
    |> Money.positive?()
  end

  defp update_balance(%Balance{} = balance, amount) do
    if balance |> validate_balance_change(amount) do
      new_amount = balance.amount |> Money.add(amount)

      balance
      |> Balance.changeset(%{amount: new_amount})
      |> Repo.update()
    else
      {:error, "Invalid changes on balance", 500}
    end
  end

  @spec withdrawal(Banking.Bank.Account.t(), any) :: nil
  def withdrawal(%Account{id: account_id} = account, %Money{} = amount) do
    amount =
      amount
      |> Money.abs()
      |> Money.neg()

    transaction_attrs = %{account_id: account_id, amount: amount}

    with {:ok, transaction} <- transaction_attrs |> create_transaction(),
         %Balance{} = balance <- account_id |> get_balance(),
         {:ok, _} <- balance |> update_balance(transaction.amount) do
      account =
        account
        |> Repo.preload(:balance, force: true)
        |> Repo.preload(:user, force: true)

      Task.async(fn -> send_withdrawal_mail(account, transaction) end)
      {:ok, account, transaction}
    end
  end

  def withdrawal(%Account{} = account, amount) when is_integer(amount) do
    account |> withdrawal(amount |> Money.new())
  end

  def withdrawal(_, _), do: {:error, "Invalid Account"}

  def send_withdrawal_mail(%Account{} = account, %Transaction{} = transaction) do
    IO.puts("Withdrawal has been success")
    IO.puts("from: noreply, to: #{account.user.email}")
    IO.puts("Withdrawal of #{transaction.amount}")
  end

  @spec transfer(Banking.Bank.Account.t(), Banking.Bank.Account.t(), integer | Money.t()) :: any
  def transfer(%Account{id: account_a_id}, %Account{id: account_b_id}, %Money{} = amount) do
    amount_a =
      amount
      |> Money.abs()
      |> Money.neg()

    amount_b =
      amount
      |> Money.abs()

    transaction_a_attrs = %{account_id: account_a_id, amount: amount_a}
    transaction_b_attrs = %{account_id: account_b_id, amount: amount_b}

    Repo.transaction(fn ->
      with {:ok, transaction_a} <- transaction_a_attrs |> create_transaction(),
           {:ok, transaction_b} <- transaction_b_attrs |> create_transaction(),
           %Balance{} = balance_a <- account_a_id |> get_balance(),
           %Balance{} = balance_b <- account_b_id |> get_balance(),
           {:ok, _} <- balance_a |> update_balance(transaction_a.amount),
           {:ok, _} <- balance_b |> update_balance(transaction_b.amount) do
        %{
          transaction_a: %{
            transaction_id: transaction_a.id,
            account_id: account_a_id,
            amount: transaction_a.amount,
            date: transaction_a.inserted_at
          },
          transaction_b: %{
            transaction_id: transaction_b.id,
            account_id: account_b_id,
            amount: transaction_b.amount,
            date: transaction_b.inserted_at
          }
        }
      else
        _ -> Repo.rollback(:transfer_not_allowed)
      end
    end)
  end

  def transfer(%Account{} = account_a, %Account{} = account_b, amount) do
    amount = amount |> Money.new()

    account_a
    |> transfer(account_b, amount)
  end

  def transfer(_, _, _), do: {:error, "Invalid accounts"}

  def report do
    %{
      today: Query.get_all_transactions_today() |> Repo.all() |> process_transaction(),
      month:
        Query.get_all_transactions_month()
        |> Repo.all()
        |> process_transaction()
        |> group_by_day(),
      year:
        Query.get_all_transactions_year()
        |> Repo.all()
        |> process_transaction()
        |> group_by_month()
        |> Enum.reduce(%{}, fn {k, v}, acc ->
          acc
          |> Map.merge(%{k => v |> group_by_day()})
        end)
    }
  end

  defp process_transaction(transactions) do
    transactions
    |> Enum.map(fn t ->
      %{
        transaction_id: t.id,
        account_id: t.account_id,
        amount: t.amount,
        date: t.inserted_at
      }
    end)
  end

  defp group_by_month(transactions) do
    transactions
    |> Enum.group_by(&(&1.date |> Timex.format!("{0M}")))
  end

  defp group_by_day(transactions) do
    transactions
    |> Enum.group_by(&(&1.date |> Timex.format!("{0D}")))
  end
end
