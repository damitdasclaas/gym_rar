defmodule GymRar.Repo.Migrations.CreateWorkoutTemplateExercises do
  use Ecto.Migration

  def change do
    create table(:workout_template_exercises) do
      add :workout_template_id, references(:workout_templates, on_delete: :delete_all), null: false
      add :exercise_id, references(:exercises, on_delete: :delete_all), null: false
      add :position, :integer, null: false, default: 0
      add :default_weight_kg, :decimal, precision: 8, scale: 2
      add :default_weight_bodyweight, :boolean, null: false, default: false
      add :default_weight_extra_kg, :decimal, precision: 8, scale: 2
      add :default_reps, :integer
      add :default_sets, :integer, null: false, default: 1

      timestamps(type: :utc_datetime)
    end

    create index(:workout_template_exercises, [:workout_template_id])
    create index(:workout_template_exercises, [:exercise_id])
  end
end
