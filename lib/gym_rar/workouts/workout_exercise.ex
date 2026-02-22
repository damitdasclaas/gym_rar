defmodule GymRar.Workouts.WorkoutExercise do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_exercises" do
    field :position, :integer, default: 0
    field :extra_notes, :string
    field :from_template, :boolean, default: true
    belongs_to :workout, GymRar.Workouts.Workout
    belongs_to :exercise, GymRar.Exercises.Exercise
    has_many :sets, GymRar.Workouts.Set

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_exercise, attrs) do
    workout_exercise
    |> cast(attrs, [:position, :extra_notes, :from_template, :workout_id, :exercise_id])
    |> validate_required([:workout_id, :exercise_id])
    |> foreign_key_constraint(:workout_id)
    |> foreign_key_constraint(:exercise_id)
  end
end
