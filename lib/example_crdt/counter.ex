defmodule ExampleCRDT.Counter do
  use GenServer

  @update_rate 100

  def start_link(name: name) do
    state = %{
      name: name,
      value: %{name => {0, 0}},
      online: true
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  def get(counter) do
    counter
    |> GenServer.call(:get)
    |> Map.update(:value, 0, &sum_values/1)
  end

  defp sum_values(values) do
    values
    |> Map.values()
    |> Enum.reduce(fn {p, n}, {q, m} -> {p + q, n + m} end)
    |> then(fn {p, n} -> p - n end)
  end

  def inc(counter) do
    GenServer.cast(counter, :inc)
  end

  def dec(counter) do
    GenServer.cast(counter, :dec)
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
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:inc, state = %{name: name}) do
    new_state =
      state
      |> update_in([:value, name], fn {p, n} -> {p + 1, n} end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:dec, state = %{name: name}) do
    new_state =
      state
      |> update_in([:value, name], fn {p, n} -> {p, n + 1} end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:toggle_online, state) do
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
    Map.merge(v, u, fn _k, {p, n}, {q, m} ->
      {max(p, q), max(n, m)}
    end)
  end

  @impl true
  def handle_info(:synchronizer, state) do
    if state.online, do: send_state(state)

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
