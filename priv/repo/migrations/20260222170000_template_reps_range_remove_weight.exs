defmodule GymRar.Repo.Migrations.TemplateRepsRangeRemoveWeight do
  use Ecto.Migration

  def change do
    alter table(:workout_template_exercises) do
      remove :default_weight_kg
      remove :default_weight_bodyweight
      remove :default_weight_extra_kg
      remove :default_reps
      add :default_reps_min, :integer
      add :default_reps_max, :integer
    end
  end
end
