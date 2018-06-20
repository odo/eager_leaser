defmodule EagerLeaser.DB do

  defmodule Lease do
    defstruct [:id, :ts, :from]
  end

  use GenServer

  @ids (1..100)
  @timeout 10

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def lease(from) do
    GenServer.call(__MODULE__, {:lease, from})
  end

  def renew(id, from) do
    GenServer.call(__MODULE__, {:renew, id, from})
  end

  def return(id) do
    GenServer.call(__MODULE__, {:return, id})
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  def init(_) do
    {:ok, %{items: @ids, leases: []}}
  end

  def handle_call({:lease, from}, _from, %{items: items, leases: leases} = state) do
    id = find_available(Enum.shuffle(items), leases)
    next_leases = add_lease(id, from, leases)
    {:reply, id, %{state | leases: next_leases}}
  end
  def handle_call({:renew, renew_id, renew_from}, _from, %{leases: leases} = state) do
    next_leases = Enum.map(
      leases,
      fn(%Lease{id: ^renew_id, from: from} = lease) ->
        case from do
          ^renew_from ->
            %Lease{lease | ts: now()}
          _ ->
            # IO.inspect leases
            throw({:from, from, "=!=", renew_from})
        end
        (lease) ->
          lease
      end
    )
    {:reply, :ok, %{state | leases: next_leases}}
  end
  def handle_call({:return, return_id}, _from, %{leases: leases} = state) do
    next_leases = Enum.reject(leases, fn(%Lease{id: id}) -> id == return_id end )
    {:reply, :ok, %{state | leases: next_leases}}
  end

  def handle_call(:list, _from, %{leases: leases} = state) do
    states =
    Enum.reduce(
      @ids,
      %{taken: [], expired: [], free: []},
      fn(id, acc) ->
        {lease, category} = category(id, leases)
        Map.put(acc, category, [lease|Map.get(acc, category)])
      end
    )
    now = now()
    IO.inspect({now, :taken, printable_leases(states.taken)}, charlists: :as_lists)
    IO.inspect({now, :expired, printable_leases(states.expired)}, charlists: :as_lists)
    IO.inspect({now, :free, states.free}, charlists: :as_lists)
    {:reply, :ok, state}
  end

  defp printable_leases(leases) do
    Enum.reduce(
      leases,
      %{},
      fn(%Lease{from: from, id: id}, acc) ->
        Map.put(acc, from, ([id|Map.get(acc, from, [])]))
      end
    )
  end

  defp category(id, []) do
    {id, :free}
  end
  defp category(id, [%Lease{id: id, ts: ts} = lease|_]) do
    case expired?(ts) do
      true  -> {lease, :expired}
      false -> {lease, :taken}
    end
  end
  defp category(id, [_|rest]) do
    category(id, rest)
  end

  defp find_available([], _), do: nil
  defp find_available([id|rest], leases) do
     case available?(id, leases) do
        true -> id
        false -> find_available(rest, leases)
     end
  end

  defp available?(id, leases) do
    not Enum.any?(leases, fn(lease) -> lease_matches?(id, lease) end)
  end

  defp lease_matches?(id, %Lease{ts: ts, id: id}), do: not expired?(ts)
  defp lease_matches?(_, _), do: false

  defp now, do: System.system_time(:seconds)

  # we put the lease and are terminating
  defp add_lease(nil, _, []), do: []
  # we went through all the leases but did not put the new one yet
  # so we add it at the end
  defp add_lease(id,  from, []) do
    [%Lease{id: id, from: from, ts: now()}]
  end
  # we found a matching lease but expired lease
  # so we put it in its place
  defp add_lease(id, from, [%Lease{id: id, ts: ts}=lease|rest]) do
    case expired?(ts) do
      true ->
        :noop
      false ->
        IO.inspect({now(), lease})
        throw({:adding_non_expired_lease, id})
    end
    [%Lease{id: id, from: from, ts: now()}|add_lease(nil, from, rest)]
  end
  defp add_lease(id, from, [lease|rest]) do
    [lease|add_lease(id, from, rest)]
  end

  defp expired?(ts) when is_integer(ts) do
    ts < (now() - @timeout)
  end

end
