defmodule GymRarWeb.ExerciseLive do
  use GymRarWeb, :live_view

  alias GymRar.Exercises
  alias GymRar.Exercises.Exercise

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    exercises = Exercises.list_exercises(user_id)

    socket =
      socket
      |> assign(:exercises, exercises)
      |> assign(:form_exercise, nil)
      |> assign_form(nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header class="mb-6">
        Übungen
        <:subtitle>Deine Übungen verwalten</:subtitle>
      </.header>

      <.simple_form
        :if={@form_exercise}
        for={@form}
        id="exercise_form"
        phx-submit="save"
        phx-change="validate"
        class="mb-6 rounded-lg border border-[#c5d8d1] bg-[#c5d8d1]/30 p-4"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <:actions>
          <.button>Speichern</.button>
          <.button type="button" variant="outline" phx-click="cancel_form">
            Abbrechen
          </.button>
        </:actions>
      </.simple_form>

      <div :if={@form_exercise == nil} class="mb-4">
        <.button phx-click="new">+ Übung hinzufügen</.button>
      </div>

      <div class="rounded-lg border border-zinc-200 bg-white shadow-sm">
        <ul class="divide-y divide-zinc-200" id="exercises">
          <li :for={exercise <- @exercises} class="flex items-center justify-between px-4 py-3">
            <span class="font-medium text-zinc-900"><%= exercise.name %></span>
            <div class="flex gap-2">
              <.button
                phx-click="edit"
                phx-value-id={exercise.id}
                class="min-h-[44px] min-w-[44px] bg-zinc-100 text-zinc-900 hover:bg-zinc-200"
              >
                Bearbeiten
              </.button>
              <.link
                phx-click={JS.push("delete", value: %{id: exercise.id}) |> JS.transition("fade-out", time: 200)}
                data-confirm="Übung wirklich löschen?"
                class="rounded-lg border border-zinc-300 px-3 py-2 text-sm font-medium text-zinc-700 hover:bg-zinc-50 min-h-[44px] min-w-[44px] inline-flex items-center justify-center"
              >
                Löschen
              </.link>
            </div>
          </li>
        </ul>
        <p :if={@exercises == []} class="px-4 py-8 text-center text-zinc-500">
          Noch keine Übungen. Klicke auf „Übung hinzufügen“.
        </p>
      </div>
    </div>
    """
  end

  def handle_event("new", _, socket) do
    {:noreply,
     socket
     |> assign(:form_exercise, %Exercise{})
     |> assign_form(Exercises.change_exercise(%Exercise{}))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    exercise = Exercises.get_exercise!(user_id, id)

    {:noreply,
     socket
     |> assign(:form_exercise, exercise)
     |> assign_form(Exercises.change_exercise(exercise))}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply,
     socket
     |> assign(:form_exercise, nil)
     |> assign_form(nil)}
  end

  def handle_event("save", %{"exercise" => params}, socket) do
    user_id = socket.assigns.current_user.id

    case maybe_save_exercise(socket.assigns.form_exercise, user_id, params) do
      {:ok, _} ->
        exercises = Exercises.list_exercises(user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Übung gespeichert.")
         |> assign(:exercises, exercises)
         |> assign(:form_exercise, nil)
         |> assign_form(nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"exercise" => params}, socket) do
    changeset =
      (socket.assigns.form_exercise || %Exercise{})
      |> Exercise.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    exercise = Exercises.get_exercise!(user_id, id)
    {:ok, _} = Exercises.delete_exercise(exercise)

    exercises = Exercises.list_exercises(user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Übung gelöscht.")
     |> assign(:exercises, exercises)}
  end

  defp maybe_save_exercise(%Exercise{id: nil}, user_id, params) do
    Exercises.create_exercise(user_id, params)
  end

  defp maybe_save_exercise(%Exercise{} = exercise, _user_id, params) do
    Exercises.update_exercise(exercise, params)
  end

  defp assign_form(socket, nil), do: assign(socket, :form, nil)

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "exercise"))
  end
end
