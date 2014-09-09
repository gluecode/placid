defmodule Placid.HandlerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "before_hook/1 all" do
    conn = conn(:get, "/")
      |> Placid.HandlerTest.Router.call([])

    assert get_resp_header(conn, "content-type") === ["application/json; charset=utf-8"]
  end

  test "before_hook/2 only show" do
    conn = conn(:get, "/show")
      |> Placid.HandlerTest.Router.call([])

    assert get_resp_header(conn, "content-type") === ["application/json; charset=utf-8"]
    assert conn.assigns[:id] === 1

    conn = conn(:get, "/")
      |> Placid.HandlerTest.Router.call([])

    assert get_resp_header(conn, "content-type") === ["application/json; charset=utf-8"]
    refute conn.assigns[:id] === 1
  end

  test "after_hook/1 all" do
    conn = conn(:get, "/")
      |> Placid.HandlerTest.Router.call([])

    assert conn.private[:id] === 2
  end

  test "after_hook/2 only show" do
    conn = conn(:get, "/show")
      |> Placid.HandlerTest.Router.call([])

    assert conn.state === :sent
    assert conn.private[:id] === 2

    conn = conn(:get, "/")
      |> Placid.HandlerTest.Router.call([])

    refute conn.state === :sent
    assert conn.private[:id] === 2
  end

  defmodule Router do
    use Placid.Router
    alias Placid.HandlerTest.Handler

    get "/", Handler, :index
    get "/show", Handler, :show
  end

  defmodule Handler do
    use Placid.Handler

    plug :set_json, run: :before
    plug :set_assign, run: :before, only: [:show]

    plug :send_response, run: :after, only: [:show]
    plug :set_private, run: :after

    def index(conn, _args) do
      conn |> resp(200, "[]")
    end

    def show(conn, _args) do
      conn |> resp(200, "[]")
    end

    ## Hooks

    def set_json(conn, _) do
      conn |> put_resp_header("content-type", "application/json; charset=utf-8")
    end

    def set_assign(conn, _) do
      conn |> assign(:id, 1)
    end

    def send_response(conn, _) do
      conn |> send_resp
    end

    def set_private(conn, _) do
      conn |> assign_private(:id, 2)
    end
  end
end