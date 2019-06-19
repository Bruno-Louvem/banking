defmodule BankingWeb.AccountControllerTest do
  use BankingWeb.ConnCase

  import Banking.Factory

  @valid_attrs attrs(:account)

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))
      assert json_response(conn, 200) == []
    end
  end
end
