defmodule GymRar.WorkoutTemplates do
  @moduledoc """
  Context für Workout-Templates. Alle Abfragen sind user-scoped.
  """

  import Ecto.Query
  alias GymRar.Repo
  alias GymRar.WorkoutTemplates.WorkoutTemplate
  alias GymRar.WorkoutTemplates.WorkoutTemplateExercise

  def list_workout_templates(user_id) do
    WorkoutTemplate
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  def list_workout_templates_with_exercises(user_id) do
    exercises_ordered = from(te in WorkoutTemplateExercise, order_by: [asc: te.position], preload: :exercise)

    WorkoutTemplate
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], asc: t.name)
    |> preload(workout_template_exercises: ^exercises_ordered)
    |> Repo.all()
  end

  def get_workout_template!(user_id, id) do
    WorkoutTemplate
    |> where([t], t.user_id == ^user_id and t.id == ^id)
    |> Repo.one!()
  end

  def get_workout_template_with_exercises!(user_id, id) do
    WorkoutTemplate
    |> where([t], t.user_id == ^user_id and t.id == ^id)
    |> preload(workout_template_exercises: :exercise)
    |> Repo.one!()
  end

  def create_workout_template(user_id, attrs \\ %{}) do
    attrs = Map.put(attrs, "user_id", user_id)
    %WorkoutTemplate{}
    |> WorkoutTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_template(%WorkoutTemplate{} = template, attrs) do
    template
    |> WorkoutTemplate.changeset(attrs)
    |> Repo.update()
  end

  def delete_workout_template(%WorkoutTemplate{} = template) do
    Repo.delete(template)
  end

  def change_workout_template(%WorkoutTemplate{} = template, attrs \\ %{}) do
    WorkoutTemplate.changeset(template, attrs)
  end

  # WorkoutTemplateExercise
  def add_exercise_to_template(template_id, exercise_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put("workout_template_id", template_id)
      |> Map.put("exercise_id", exercise_id)

    %WorkoutTemplateExercise{}
    |> WorkoutTemplateExercise.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_template_exercise(%WorkoutTemplateExercise{} = te, attrs) do
    te
    |> WorkoutTemplateExercise.changeset(attrs)
    |> Repo.update()
  end

  def remove_exercise_from_template(%WorkoutTemplateExercise{} = te) do
    Repo.delete(te)
  end

  def list_template_exercises(workout_template_id) do
    WorkoutTemplateExercise
    |> where([te], te.workout_template_id == ^workout_template_id)
    |> order_by([te], asc: te.position)
    |> preload(:exercise)
    |> Repo.all()
  end
end
