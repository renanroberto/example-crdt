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

    state = %{
      "counter1" => Counter.get(:counter1),
      "counter2" => Counter.get(:counter2),
      "counter3" => Counter.get(:counter3)
    }

    {:noreply, assign(socket, state: state)}
  end
end
