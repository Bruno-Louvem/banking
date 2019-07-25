defmodule BankingWeb.V1.AuthView do
  use BankingWeb, :view

  alias BankingWeb.AccountView

  def render("auth.json", %{token: token}) do
    %{token: token}
  end
end
