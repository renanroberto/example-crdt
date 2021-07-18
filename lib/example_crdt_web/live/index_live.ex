defmodule ExampleCRDTWeb.IndexLive do
  use ExampleCRDTWeb, :live_view

  alias ExampleCRDT.Counter

  @update_rate 100

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send(self(), "update", [])
    end

    {:ok, assign(socket, state: %{})}
  end

  @impl true
  def handle_event("inc", %{"counter" => counter}, socket) do
    Counter.inc(:"#{counter}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("dec", %{"counter" => counter}, socket) do
    Counter.dec(:"#{counter}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_online", %{"counter" => counter}, socket) do
    Counter.toggle_online(:"#{counter}")

    {:noreply, socket}
  end

  @impl true
  def handle_info("update", socket) do
    Process.send_after(self(), "update", @update_rate)

    state =
      ExampleCRDT.Supervisor.Counter
      |> Supervisor.which_children()
      |> Enum.map(fn {name, _, _, _} -> name end)
      |> Enum.reduce(%{}, fn counter, state ->
        Map.put(state, counter, Counter.get(:"#{counter}"))
      end)

    {:noreply, assign(socket, state: state)}
  end
end
