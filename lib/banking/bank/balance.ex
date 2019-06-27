defmodule Banking.Bank.Balance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "balances" do
    belongs_to :account, Banking.Bank.Account, type: :binary_id

    field :amount, Money.Ecto.Amount.Type

    timestamps()
  end

  @required_fields ~w(account_id amount)a

  @doc false
  def changeset(balance, attrs) do
    balance
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
