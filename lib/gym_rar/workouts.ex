defmodule GymRar.Workouts do
  @moduledoc """
  Context für durchgeführte Workouts (Archiv). Alle Abfragen sind user-scoped.
  """

  import Ecto.Query
  alias GymRar.Repo
  alias GymRar.Workouts.Workout
  alias GymRar.Workouts.WorkoutExercise
  alias GymRar.Workouts.WorkoutLocation
  alias GymRar.Workouts.Set

  def list_workouts(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    order = Keyword.get(opts, :order, desc: :performed_at)

    Workout
    |> where([w], w.user_id == ^user_id)
    |> order_by([w], ^order)
    |> limit(^limit)
    |> preload([:workout_location, workout_exercises: [:exercise, :sets]])
    |> Repo.all()
  end

  @doc "Letztes verwendetes Gym (Ort des zuletzt gespeicherten Workouts)."
  def last_workout_location(user_id) do
    Workout
    |> where([w], w.user_id == ^user_id and not is_nil(w.workout_location_id))
    |> order_by([w], desc: w.inserted_at)
    |> limit(1)
    |> preload(:workout_location)
    |> Repo.one()
    |> case do
      nil -> nil
      w -> w.workout_location
    end
  end

  def get_workout!(user_id, id) do
    Workout
    |> where([w], w.user_id == ^user_id and w.id == ^id)
    |> preload([:workout_location, workout_exercises: [:exercise, :sets]])
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

  # WorkoutLocation
  def list_locations(user_id) do
    WorkoutLocation
    |> where([l], l.user_id == ^user_id)
    |> order_by([l], asc: l.name)
    |> Repo.all()
  end

  def get_location(user_id, id) when is_integer(id) do
    WorkoutLocation
    |> where([l], l.user_id == ^user_id and l.id == ^id)
    |> Repo.one()
  end

  def get_location(_user_id, _), do: nil

  def get_location!(user_id, id) do
    WorkoutLocation
    |> where([l], l.user_id == ^user_id and l.id == ^id)
    |> Repo.one!()
  end

  def create_location(user_id, attrs \\ %{}) do
    attrs = Map.put(attrs, "user_id", user_id)
    %WorkoutLocation{}
    |> WorkoutLocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Erstellt ein Workout aus einem Template inkl. WorkoutExercises und Sets.
  template: mit preload workout_template_exercises (sortiert nach position).
  rows_data: Liste von
    - %{template_exercise_id: id, sets: [...]} (Template-Übungen)
    - %{exercise_id: id, sets: [...]} (temporäre Übungen)
  location_id: optional.
  opts: [body_weight_kg: decimal]
  """
  def create_workout_from_template(user_id, template, rows_data, location_id \\ nil, opts \\ []) do
    now = DateTime.utc_now()
    attrs = %{
      "user_id" => user_id,
      "workout_template_id" => template.id,
      "name" => template.name,
      "performed_at" => Date.utc_today(),
      "saved_at" => now
    }
    attrs = if location_id, do: Map.put(attrs, "workout_location_id", location_id), else: attrs
    attrs = case Keyword.get(opts, :body_weight_kg) do
      nil -> attrs
      "" -> attrs
      kg -> Map.put(attrs, "body_weight_kg", parse_decimal(kg))
    end

    template_count = length(template.workout_template_exercises)
    temp_rows = Enum.filter(rows_data, & &1["exercise_id"])

    Repo.transaction(fn ->
      workout =
        %Workout{}
        |> Workout.changeset(attrs)
        |> Repo.insert!()

      template.workout_template_exercises
      |> Enum.with_index()
      |> Enum.each(fn {te, pos} ->
        row = Enum.find(rows_data, &(&1["template_exercise_id"] == te.id))
        if row do
          insert_workout_exercise_with_sets(workout.id, te.exercise_id, pos, true, row["sets"] || [])
        end
      end)

      temp_rows
      |> Enum.with_index()
      |> Enum.each(fn {row, idx} ->
        insert_workout_exercise_with_sets(
          workout.id,
          row["exercise_id"],
          template_count + idx,
          false,
          row["sets"] || []
        )
      end)

      workout
    end)
  end

  defp insert_workout_exercise_with_sets(workout_id, exercise_id, position, from_template, sets) do
    we_attrs = %{
      "workout_id" => workout_id,
      "exercise_id" => exercise_id,
      "position" => position,
      "from_template" => from_template
    }
    we =
      %WorkoutExercise{}
      |> WorkoutExercise.changeset(we_attrs)
      |> Repo.insert!()

    sets
    |> Enum.with_index()
    |> Enum.each(fn {set_attrs, set_pos} ->
      set_attrs =
        set_attrs
        |> Map.put("workout_exercise_id", we.id)
        |> Map.put("position", set_pos)
        |> Map.put("from_template", from_template)
        |> normalize_set_attrs()

      %Set{}
      |> Set.changeset(set_attrs)
      |> Repo.insert!()
    end)
  end

  defp parse_decimal(n) when is_number(n), do: Decimal.new(to_string(n))
  defp parse_decimal(str) when is_binary(str) do
    case Decimal.parse(str) do
      {d, _} -> d
      :error -> nil
    end
  end
  defp parse_decimal(_), do: nil

  defp normalize_set_attrs(attrs) do
    attrs
    |> maybe_parse_decimal("weight_kg")
    |> maybe_parse_decimal("weight_extra_kg")
    |> maybe_bool("weight_bodyweight")
    |> maybe_int("reps")
    |> maybe_int("duration_seconds")
    |> Map.put_new("skipped", false)
  end

  defp maybe_bool(attrs, key) do
    case Map.get(attrs, key) do
      true -> Map.put(attrs, key, true)
      "true" -> Map.put(attrs, key, true)
      _ -> Map.put(attrs, key, false)
    end
  end

  defp maybe_parse_decimal(attrs, key) do
    case Map.get(attrs, key) do
      nil -> attrs
      "" -> Map.put(attrs, key, nil)
      val when is_binary(val) ->
        case Decimal.parse(val) do
          {d, _} -> Map.put(attrs, key, d)
          :error -> Map.put(attrs, key, nil)
        end
      _ -> attrs
    end
  end

  defp maybe_int(attrs, key) do
    case Map.get(attrs, key) do
      nil -> attrs
      "" -> Map.put(attrs, key, nil)
      val when is_binary(val) ->
        case Integer.parse(val) do
          {n, _} -> Map.put(attrs, key, n)
          :error -> Map.put(attrs, key, nil)
        end
      _ -> attrs
    end
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
  location_id: optional – wenn gesetzt, nur Workouts an diesem Ort (z. B. gleiches Gym).
  """
  def exercise_history(user_id, exercise_id, limit \\ 3, location_id \\ nil) do
    q =
      from(we in WorkoutExercise,
        join: w in Workout,
        on: w.id == we.workout_id,
        where: we.exercise_id == ^exercise_id and w.user_id == ^user_id,
        order_by: [desc: w.performed_at],
        limit: ^limit,
        preload: [:workout, :sets]
      )

    q = if location_id do
      from([we, w] in q, where: w.workout_location_id == ^location_id)
    else
      q
    end

    Repo.all(q)
  end

  # Hilfsfunktion: performed_at auf heute setzen falls nicht gesetzt
  defp maybe_set_performed_at(attrs) do
    case Map.get(attrs, :performed_at) do
      nil -> Map.put(attrs, :performed_at, Date.utc_today())
      _ -> attrs
    end
  end
end
