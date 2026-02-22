defmodule GymRar.Repo.Migrations.AddDurationToTemplateAndSets do
  use Ecto.Migration

  def change do
    alter table(:workout_template_exercises) do
      add :default_duration_seconds, :integer
    end

    alter table(:sets) do
      add :duration_seconds, :integer
    end
  end
end
