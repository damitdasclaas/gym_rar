defmodule GymRar.Repo.Migrations.AddSavedAtAndBodyWeightToWorkouts do
  use Ecto.Migration

  def change do
    alter table(:workouts) do
      add :saved_at, :utc_datetime, null: true
      add :body_weight_kg, :decimal, null: true
    end

    # Bestehende Workouts: saved_at = inserted_at (erster Speicherzeitpunkt)
    execute(
      "UPDATE workouts SET saved_at = inserted_at WHERE saved_at IS NULL",
      ""
    )
  end
end
