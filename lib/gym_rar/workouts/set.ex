defmodule GymRar.Workouts.Set do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sets" do
    field :position, :integer, default: 0
    field :weight_kg, :decimal
    field :weight_bodyweight, :boolean, default: false
    field :weight_extra_kg, :decimal
    field :reps, :integer
    field :from_template, :boolean, default: true
    field :skipped, :boolean, default: false
    belongs_to :workout_exercise, GymRar.Workouts.WorkoutExercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(set, attrs) do
    set
    |> cast(attrs, [
      :position,
      :weight_kg,
      :weight_bodyweight,
      :weight_extra_kg,
      :reps,
      :from_template,
      :skipped,
      :workout_exercise_id
    ])
    |> validate_required([:workout_exercise_id])
    |> foreign_key_constraint(:workout_exercise_id)
  end
end
