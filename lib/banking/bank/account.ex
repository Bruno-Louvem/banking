defmodule Banking.Bank.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "accounts" do

    field :name, :string
    field :email, :string

    timestamps()
  end

  @required_fields ~w(name email)a

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
  end
end
