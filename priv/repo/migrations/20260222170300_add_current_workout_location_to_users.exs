defmodule GymRar.Repo.Migrations.AddCurrentWorkoutLocationToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_workout_location_id, references(:workout_locations, on_delete: :nilify_all)
    end

    create index(:users, [:current_workout_location_id])
  end
end
