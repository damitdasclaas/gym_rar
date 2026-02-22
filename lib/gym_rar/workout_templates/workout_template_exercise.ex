defmodule GymRar.WorkoutTemplates.WorkoutTemplateExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_template_exercises" do
    field :position, :integer, default: 0
    field :default_reps_min, :integer
    field :default_reps_max, :integer
    field :default_duration_seconds, :integer
    field :default_sets, :integer, default: 1
    belongs_to :workout_template, GymRar.WorkoutTemplates.WorkoutTemplate
    belongs_to :exercise, GymRar.Exercises.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(template_exercise, attrs) do
    template_exercise
    |> cast(attrs, [
      :position,
      :default_reps_min,
      :default_reps_max,
      :default_duration_seconds,
      :default_sets,
      :workout_template_id,
      :exercise_id
    ])
    |> validate_required([:workout_template_id, :exercise_id])
    |> validate_number(:default_sets, greater_than_or_equal_to: 1)
    |> foreign_key_constraint(:workout_template_id)
    |> foreign_key_constraint(:exercise_id)
  end
end
