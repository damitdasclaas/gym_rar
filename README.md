# GymRAR

## Lokales Setup (mit Docker für Postgres)

  * Postgres starten: `docker compose up -d`
  * Abhängigkeiten: `mix setup`
  * DB anlegen & migrieren: `mix ecto.create && mix ecto.migrate`
  * Server starten: `mix phx.server` (oder `iex -S mix phx.server`)

Dann im Browser [`localhost:4000`](http://localhost:4000) öffnen. Die App verbindet sich gegen die Postgres-Instanz im Container (gleiche Credentials wie in `config/dev.exs`).

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
