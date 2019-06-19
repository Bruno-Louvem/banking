defmodule Banking.BankTest do
  use Banking.DataCase

  alias Banking.Bank

  describe "accounts" do
    alias Banking.Bank.Account

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
  end
end
