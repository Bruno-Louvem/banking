defmodule Banking.BankTest do
  use Banking.DataCase

  alias Banking.Bank
  alias Banking.Bank.Account

  describe "accounts" do

    @valid_account_attrs %{email: Faker.Internet.email(), name: Faker.Name.name()}
    @invalid_account_attrs %{email: nil, name: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_account_attrs)
        |> Bank.create_account()

      account
    end

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      [loaded_account] = Bank.list_account()
      assert loaded_account.id == account.id
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = Bank.create_account(@valid_account_attrs)
      assert account.email == @valid_account_attrs.email
      assert account.name == @valid_account_attrs.name
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_account_attrs)
    end

    test "test signup" do
      assert {:ok, %Account{} = account} = Bank.signup(@valid_account_attrs)
    end

    test "test signup with invalid attrs" do
      assert {:error, %Ecto.Changeset{}} = Bank.signup(@invalid_account_attrs)
    end
  end

  describe "transacitonal" do
    test "create deposit with valid attrs" do
      assert {:ok, %Account{} = account} = Bank.signup(@valid_account_attrs)
      assert account.balance.amount |> Money.equals?(Money.new(1000))

      assert {:ok, account} = account |> Bank.deposit(1000)
      assert account.balance.amount |> Money.equals?(Money.new(2000))
    end

    test "create deposit with invalid attrs" do
      assert {:ok, %Account{} = account} = Bank.signup(@valid_account_attrs)
      assert account.balance.amount |> Money.equals?(Money.new(1000))

      assert {:error, _} = account |> Bank.deposit(nil)
    end

    test "create withdrawal with valid attrs" do
      assert {:ok, %Account{} = account} = Bank.signup(@valid_account_attrs)
      assert account.balance.amount |> Money.equals?(Money.new(1000))

      assert {:ok, account} = account |> Bank.withdrawal(500)
      assert account.balance.amount |> Money.equals?(Money.new(500))
    end

    test "create withdrawal with amount greater than limit" do
      assert {:ok, %Account{} = account} = Bank.signup(@valid_account_attrs)
      assert account.balance.amount |> Money.equals?(Money.new(1000))

      assert {:error, _} = account |> Bank.withdrawal(1001)
    end

    test "create a transfer between 2 accounts with valid params" do
      assert {:ok, %Account{} = account_a} = Bank.signup(@valid_account_attrs)
      assert {:ok, %Account{} = account_b} =
        %{email: Faker.Internet.email(), name: Faker.Name.name()} |> Bank.signup()

      assert {:ok, %{transaction_a: transaction_a, transaction_b: transaction_b}} =
        account_a |> Bank.transfer(account_b, 500)

      assert transaction_a.account_id == account_a.id
      assert transaction_b.account_id == account_b.id
      assert transaction_a |> Map.has_key?(:transaction_id)
      assert transaction_b |> Map.has_key?(:transaction_id)

      {:ok, account_a} = Bank.get_account(account_a.id)
      {:ok, account_b} = Bank.get_account(account_b.id)

      assert account_a.balance.amount |> Money.equals?(Money.new(500))
      assert account_b.balance.amount |> Money.equals?(Money.new(1500))
    end

    test "create a transfer between 2 accounts with invalid params" do
      assert {:ok, %Account{} = account_a} = Bank.signup(@valid_account_attrs)
      assert {:ok, %Account{} = account_b} =
        %{email: Faker.Internet.email(), name: Faker.Name.name()} |> Bank.signup()

      assert {:error, _} = account_a |> Bank.transfer(account_b, 2000)
    end
  end
end
