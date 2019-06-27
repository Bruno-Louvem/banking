defmodule Banking.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias Banking.Repo
  alias Banking.Bank.{Account, Balance, Transaction}

  @inital_deposit_amount Money.new(1000)

  @doc """
  Returns the list of account.

  ## Examples

      iex> list_account()
      [%Account{}, ...]

  """
  def list_account do
    Account
    |> Repo.all()
  end

  @doc """
  Returns the list of account.

  ## Examples

      iex> get_account(account_id)
      %Account{}

  """
  def get_account(account_id) do
    account =
      Account
      |> Repo.get(account_id)
      |> Repo.preload(:balance)

    {:ok, account}
  end

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

  @spec signup(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) :: any
  def signup(account_attrs) do
    with {:ok, account} <- account_attrs |> create_account(),
         {:ok, _} <- %{account_id: account.id} |> create_balance()
    do
      account |> deposit(@inital_deposit_amount)
    end
  end

  @spec deposit(any, any) :: any
  def deposit(%Account{id: account_id} = account, amount) do
    transaction_attrs = %{account_id: account_id, amount: amount}
    with {:ok, transaction} <-  transaction_attrs |> create_transaction(),
         %Balance{} = balance <- account_id |> get_balance(),
         {:ok, _} <- balance |> update_balance(transaction.amount)
    do
      account = account |> Repo.preload(:balance, force: true)
      {:ok, account}
    end
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
    |> Repo.get_by([account_id: account_id])
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
      {:error, "Invalid changes on balance"}
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
         {:ok, _} <- balance |> update_balance(transaction.amount)
    do
      account = account |> Repo.preload(:balance, force: true)
      {:ok, account}
    end
  end

  def withdrawal(%Account{} = account, amount), do: withdrawal(account, amount |> Money.new())

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

    Repo.transaction fn ->
      with {:ok, transaction_a} <- transaction_a_attrs |> create_transaction(),
           {:ok, transaction_b} <- transaction_b_attrs |> create_transaction(),
           %Balance{} = balance_a <- account_a_id |> get_balance(),
           %Balance{} = balance_b <- account_b_id |> get_balance(),
           {:ok, _} <- balance_a |> update_balance(transaction_a.amount),
           {:ok, _} <- balance_b |> update_balance(transaction_b.amount)
      do
        %{transaction_a: %{transaction_id: transaction_a.id, account_id: account_a_id},
          transaction_b: %{transaction_id: transaction_b.id, account_id: account_b_id}}
      else
        _ -> Repo.rollback(:transfer_not_allowed)
      end
    end
  end

  def transfer(%Account{} =  account_a, %Account{} = account_b, amount) do
    amount = amount |> Money.new()

    account_a
    |> transfer(account_b, amount)
  end
end
