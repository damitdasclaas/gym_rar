defmodule GymRar.Exercises do
  @moduledoc """
  Context für Übungen (exercises). Alle Abfragen sind user-scoped.
  """

  import Ecto.Query
  alias GymRar.Repo
  alias GymRar.Exercises.Exercise

  @doc """
  Liste aller Übungen eines Users, sortiert nach Name.
  """
  def list_exercises(user_id) do
    Exercise
    |> where([e], e.user_id == ^user_id)
    |> order_by([e], asc: e.name)
    |> Repo.all()
  end

  @doc """
  Holt eine Übung nach ID, nur wenn sie dem User gehört.
  """
  def get_exercise!(user_id, id), do: Repo.get_by!(Exercise, id: id, user_id: user_id)

  @doc """
  Erstellt eine Übung.
  """
  def create_exercise(user_id, attrs \\ %{}) do
    attrs = Map.put(attrs, "user_id", user_id)
    %Exercise{}
    |> Exercise.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Aktualisiert eine Übung.
  """
  def update_exercise(%Exercise{} = exercise, attrs) do
    exercise
    |> Exercise.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Löscht eine Übung.
  """
  def delete_exercise(%Exercise{} = exercise) do
    Repo.delete(exercise)
  end

  @doc """
  Gibt ein Ecto.Changeset für die Übung zurück (z. B. für Formulare).
  """
  def change_exercise(%Exercise{} = exercise, attrs \\ %{}) do
    Exercise.changeset(exercise, attrs)
  end
end
