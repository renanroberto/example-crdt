defmodule ExampleCRDT.Counter do
  use GenServer

  @update_rate 100

  def start_link(name: name) do
    state = %{
      name: name,
      value: %{name => 0},
      online: true
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def get(counter) do
    counter
    |> GenServer.call(:get)
    |> Map.values()
    |> Enum.sum()
  end

  def online?(counter) do
    GenServer.call(counter, :online)
  end

  def incr(counter) do
    GenServer.cast(counter, :incr)
  end

  def toggle_online(counter) do
    GenServer.cast(counter, :toggle_online)
  end

  @impl true
  def init(state) do
    Process.send(self(), :synchronizer, [])

    {:ok, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.value, state}
  end

  @impl true
  def handle_call(:online, _from, state) do
    {:reply, state.online, state}
  end

  @impl true
  def handle_cast(:incr, state = %{name: name}) do
    new_state =
      state
      |> update_in([:value, name], fn x -> x + 1 end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:incr, state) do
    new_state = %{state | online: !state.online}

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:sync, other_state}, state) do
    value1 = state.value
    value2 = other_state.value
    value = merge(value1, value2)

    if state.online do
      {:noreply, %{state | value: value}}
    else
      {:noreply, state}
    end
  end

  defp merge(v, u) do
    Map.merge(v, u, fn _k, x, y -> max(x, y) end)
  end

  @impl true
  def handle_info(:synchronizer, state) do
    send_state(state)

    Process.send_after(self(), :synchronizer, @update_rate)
    {:noreply, state}
  end

  defp send_state(state) do
    ExampleCRDT.Supervisor.Counter
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.map(fn pid -> GenServer.cast(pid, {:sync, state}) end)
  end
end
