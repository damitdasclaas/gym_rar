defmodule GymRar.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :workout_template_id, references(:workout_templates, on_delete: :nilify_all)
      add :name, :string, null: false
      add :performed_at, :date, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workouts, [:user_id])
    create index(:workouts, [:workout_template_id])
    create index(:workouts, [:performed_at])
  end
end
