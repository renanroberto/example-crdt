defmodule ExampleCRDT.Repo do
  use Ecto.Repo,
    otp_app: :example_crdt,
    adapter: Ecto.Adapters.Postgres
end
