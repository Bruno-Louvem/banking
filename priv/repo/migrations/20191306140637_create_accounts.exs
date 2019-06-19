defmodule Banking.Repo.Migrations.CreateParts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :email, :string

      timestamps()
    end
    create unique_index(:accounts, [:email])
  end
end
