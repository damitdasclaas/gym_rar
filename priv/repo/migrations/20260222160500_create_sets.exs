defmodule GymRar.Repo.Migrations.CreateSets do
  use Ecto.Migration

  def change do
    create table(:sets) do
      add :workout_exercise_id, references(:workout_exercises, on_delete: :delete_all), null: false
      add :position, :integer, null: false, default: 0
      add :weight_kg, :decimal, precision: 8, scale: 2
      add :weight_bodyweight, :boolean, null: false, default: false
      add :weight_extra_kg, :decimal, precision: 8, scale: 2
      add :reps, :integer
      add :from_template, :boolean, null: false, default: true
      add :skipped, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:sets, [:workout_exercise_id])
  end
end
