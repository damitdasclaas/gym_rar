defmodule GymRar.Workouts.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :performed_at, :date
    belongs_to :user, GymRar.Accounts.User
    belongs_to :workout_template, GymRar.WorkoutTemplates.WorkoutTemplate
    belongs_to :workout_location, GymRar.Workouts.WorkoutLocation
    has_many :workout_exercises, GymRar.Workouts.WorkoutExercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :performed_at, :user_id, :workout_template_id, :workout_location_id])
    |> validate_required([:name, :performed_at, :user_id])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:workout_template_id)
    |> foreign_key_constraint(:workout_location_id)
  end
end
