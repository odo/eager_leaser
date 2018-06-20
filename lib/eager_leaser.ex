defmodule EagerLeaser do

  use Application

  def start(_type, _args) do
    children = [EagerLeaser.DB, EagerLeaser.WorkerSupervisor]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def list() do
    EagerLeaser.DB.list
  end

  def start_worker() do
     EagerLeaser.WorkerSupervisor.start_child
  end

  def stop_worker() do
     EagerLeaser.WorkerSupervisor.stop_child
  end

end
