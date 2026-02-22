defmodule GymRar.Workouts.WorkoutLocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workout_locations" do
    field :name, :string
    belongs_to :user, GymRar.Accounts.User
    has_many :workouts, GymRar.Workouts.Workout

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:user_id)
  end
end
