defmodule EagerLeaser.Worker do
  use GenServer
  alias EagerLeaser.DB

  @tick 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def drain(server) do
    GenServer.cast(server, :drain)
  end

  def init(_) do
    schedule_tick()
    {:ok, []}
  end

  def schedule_tick do
    Process.send_after(self(), :tick, @tick, [])
  end

  def handle_info(:tick, leases) do
    Enum.each(leases, fn(lease) -> DB.renew(lease, self()) end)
    next_leases =
    case DB.lease(self()) do
      nil -> leases
      id -> [id|leases]
    end
    schedule_tick()
    {:noreply, next_leases}
  end

  def handle_info({:drain, id}, leases) do
    # we have to make sure we still have the id
    # we might have returned them before and just had
    # several drains in flight
    # if we don't check, we might return someone elses id
    case Enum.any?(leases, fn(lease) -> lease == id end) do
      true  -> DB.return(id)
      false -> :noop
    end
    next_leases = Enum.reject(leases, fn(lease) -> lease == id end)
    {:noreply, next_leases}
  end
  def handle_info(:stop, leases) do
    {:stop, :normal, leases}
  end

  def handle_cast(:drain, leases) do
    worker = self()
    Enum.each(
      leases,
      fn(lease) -> Process.send_after(worker, {:drain, lease}, :rand.uniform(10000), []) end
    )
    {:noreply, leases}
  end

end
