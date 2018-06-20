defmodule EagerLeaser.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.each( fn({_, worker, _, _}) -> EagerLeaser.Worker.drain(worker) end)

    DynamicSupervisor.start_child(
      __MODULE__,
      %{id: :rand.uniform(100_000), start: {EagerLeaser.Worker, :start_link, [[]]}, restart: :transient}
    )
  end

  def stop_child() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map( fn({_, worker, _, _}) -> worker end)
    |> Enum.random
    |> Process.send(:stop, [])
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
