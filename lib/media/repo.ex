defmodule Media.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :media,
    adapter: Ecto.Adapters.Postgres
end
