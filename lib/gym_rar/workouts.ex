defmodule GymRar.Workouts do
  @moduledoc """
  Context für durchgeführte Workouts (Archiv). Alle Abfragen sind user-scoped.
  """

  import Ecto.Query
  alias GymRar.Repo
  alias GymRar.Workouts.Workout
  alias GymRar.Workouts.WorkoutExercise
  alias GymRar.Workouts.Set

  def list_workouts(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    order = Keyword.get(opts, :order, desc: :performed_at)

    Workout
    |> where([w], w.user_id == ^user_id)
    |> order_by([w], ^order)
    |> limit(^limit)
    |> preload(workout_exercises: [:exercise, :sets])
    |> Repo.all()
  end

  def get_workout!(user_id, id) do
    Workout
    |> where([w], w.user_id == ^user_id and w.id == ^id)
    |> preload(workout_exercises: [:exercise, :sets])
    |> Repo.one!()
  end

  def create_workout(user_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:user_id, user_id)
      |> maybe_set_performed_at()

    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout(%Workout{} = workout, attrs) do
    workout
    |> Workout.changeset(attrs)
    |> Repo.update()
  end

  def delete_workout(%Workout{} = workout) do
    Repo.delete(workout)
  end

  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end

  # WorkoutExercise
  def add_exercise_to_workout(workout_id, exercise_id, attrs \\ %{}) do
    %WorkoutExercise{}
    |> WorkoutExercise.changeset(
      attrs
      |> Map.put(:workout_id, workout_id)
      |> Map.put(:exercise_id, exercise_id)
      |> Map.put(:from_template, false)
    )
    |> Repo.insert()
  end

  def update_workout_exercise(%WorkoutExercise{} = we, attrs) do
    we
    |> WorkoutExercise.changeset(attrs)
    |> Repo.update()
  end

  def remove_workout_exercise(%WorkoutExercise{} = we) do
    Repo.delete(we)
  end

  # Sets
  def add_set_to_workout_exercise(workout_exercise_id, attrs \\ %{}) do
    %Set{}
    |> Set.changeset(
      attrs
      |> Map.put(:workout_exercise_id, workout_exercise_id)
      |> Map.put(:from_template, false)
    )
    |> Repo.insert()
  end

  def update_set(%Set{} = set, attrs) do
    set
    |> Set.changeset(attrs)
    |> Repo.update()
  end

  def delete_set(%Set{} = set) do
    Repo.delete(set)
  end

  @doc """
  Letzte 2–3 Workout-Vorkommen einer Übung für den History-Button.
  Gibt Liste von %{workout: workout, sets: sets} zurück.
  """
  def exercise_history(user_id, exercise_id, limit \\ 3) do
    from(we in WorkoutExercise,
      join: w in Workout,
      on: w.id == we.workout_id,
      where: we.exercise_id == ^exercise_id and w.user_id == ^user_id,
      order_by: [desc: w.performed_at],
      limit: ^limit,
      preload: [:workout, :sets]
    )
    |> Repo.all()
  end

  # Hilfsfunktion: performed_at auf heute setzen falls nicht gesetzt
  defp maybe_set_performed_at(attrs) do
    case Map.get(attrs, :performed_at) do
      nil -> Map.put(attrs, :performed_at, Date.utc_today())
      _ -> attrs
    end
  end
end
