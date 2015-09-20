defmodule ConnectionTest do
  use ExUnit.Case
  import Supervisor.Spec

  test "Connections can be supervised" do
    children = [worker(RethinkDB.Connection, [])]
    {:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)
    assert Supervisor.count_children(sup) == %{active: 1, specs: 1, supervisors: 0, workers: 1}
    Process.exit(sup, :normal)
  end

  test "using Connection works with supervision" do
    children = [worker(TestConnection, [])]
    {:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)
    assert Supervisor.count_children(sup) == %{active: 1, specs: 1, supervisors: 0, workers: 1}
    Process.exit(sup, :normal)
  end

  test "reconnects on failure" do
    TestConnection.connect([port: 28014])
    %RethinkDB.Exception.ConnectionClosed{} = RethinkDB.Query.table_list |> TestConnection.run
    conn = FlakyConnection.start('localhost', 28015, 28014)
    :timer.sleep(1000)
    %RethinkDB.Record{} = RethinkDB.Query.table_list |> TestConnection.run
    FlakyConnection.stop(conn)
    %RethinkDB.Exception.ConnectionClosed{} = RethinkDB.Query.table_list |> TestConnection.run
  end
end