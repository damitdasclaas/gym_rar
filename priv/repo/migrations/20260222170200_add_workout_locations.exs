defmodule GymRar.Repo.Migrations.AddWorkoutLocations do
  use Ecto.Migration

  def change do
    create table(:workout_locations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workout_locations, [:user_id])
    create unique_index(:workout_locations, [:user_id, :name], name: :workout_locations_user_id_name_index)

    alter table(:workouts) do
      add :workout_location_id, references(:workout_locations, on_delete: :nilify_all)
    end

    create index(:workouts, [:workout_location_id])
  end
end
