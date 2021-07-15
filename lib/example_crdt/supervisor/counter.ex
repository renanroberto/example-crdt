defmodule ExampleCRDT.Supervisor.Counter do
  use Supervisor

  @number_of_replicas 3

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children =
      Enum.map(1..@number_of_replicas, fn id ->
        Supervisor.child_spec(
          {ExampleCRDT.Counter, name: :"counter#{id}"},
          id: :"counter#{id}"
        )
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
