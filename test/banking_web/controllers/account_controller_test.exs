defmodule BankingWeb.AccountControllerTest do
  use BankingWeb.ConnCase

  import Banking.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all accounts without accounts created", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))
      assert json_response(conn, 200) == []
    end

    test "lists all accounts", %{conn: conn} do
      1..10
      |> Enum.each(&(insert(:account, %{name: "Account #{&1}"})))

      conn = get(conn, Routes.account_path(conn, :index))
      account_list = json_response(conn, 200)
      assert account_list |> length() == 10
    end
  end

  describe "create" do
    test "create account", %{conn: conn} do
      account_params = %{name: Faker.Name.name(), email: Faker.Internet.email()}
      conn = post(conn, Routes.account_path(conn, :create), account_params)
      response = json_response(conn, 201)

      assert response["name"] == account_params.name
      assert response["email"] == account_params.email
      assert response |> Map.has_key?("id")
    end

    test "not create account. why? invalid params", %{conn: conn} do
      account_params = %{name: Faker.Name.name()}
      conn = post(conn, Routes.account_path(conn, :create), account_params)
      response = json_response(conn, 422)
      assert response |> Map.has_key?("errors")
    end
  end
end
