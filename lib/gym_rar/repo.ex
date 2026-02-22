defmodule GymRar.Repo do
  use Ecto.Repo,
    otp_app: :gym_rar,
    adapter: Ecto.Adapters.Postgres
end
