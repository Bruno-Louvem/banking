defmodule Banking.Repo.Migrations.CreateBalances do
  use Ecto.Migration

  def change do
    create table(:balances, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :account_id, references(:accounts, type: :uuid)
      add :amount, :integer

      timestamps()
    end

    create index(:balances, [:account_id])
  end
end
