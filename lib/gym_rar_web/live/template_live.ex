defmodule GymRarWeb.TemplateLive do
  use GymRarWeb, :live_view

  alias GymRar.WorkoutTemplates
  alias GymRar.WorkoutTemplates.WorkoutTemplate
  alias GymRar.Exercises

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case socket.assigns.live_action do
        :index ->
          socket
          |> assign(:templates, WorkoutTemplates.list_workout_templates_with_exercises(user_id))
          |> assign(:expanded_template_id, nil)

        :new ->
          template = %WorkoutTemplate{user_id: user_id}
          socket
          |> assign(:form_template, template)
          |> assign_form(WorkoutTemplates.change_workout_template(template))

        :edit ->
          template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, params["id"])
          exercises = Exercises.list_exercises(user_id)

          socket
          |> assign(:template, template)
          |> assign(:template_exercises, template.workout_template_exercises)
          |> assign(:exercises, exercises)
          |> assign(:form_template, nil)
          |> assign(:show_add_exercise, false)
          |> assign(:editing_exercise_id, nil)
          |> assign_form(nil)
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl">
      <.header class="mb-6">
        Workout-Templates
        <:subtitle>Vorlagen für deine Workouts</:subtitle>
      </.header>

      <.link navigate={~p"/exercises"} class="mb-4 inline-block text-sm text-[#06bcc1] hover:underline">
        ← Übungen
      </.link>

      <%= if @live_action == :index do %>
        <div class="mb-4">
          <.link navigate={~p"/templates/new"} class="inline-block">
            <.button>+ Template anlegen</.button>
          </.link>
        </div>
        <div class="rounded-lg border border-[#c5d8d1] bg-[#f4edea]/50">
          <ul class="divide-y divide-[#c5d8d1]">
            <li :for={tpl <- @templates} class="flex flex-col">
              <div class="flex min-h-[44px] items-center justify-between px-4 py-3">
                <button
                  type="button"
                  phx-click="toggle_template"
                  phx-value-id={tpl.id}
                  class="flex flex-1 items-center gap-2 text-left"
                >
                  <span class={["shrink-0 transition-transform", @expanded_template_id == tpl.id && "rotate-90"]}>
                    ▶
                  </span>
                  <span class="font-medium text-[#12263a]"><%= tpl.name %></span>
                  <span class="text-sm text-[#12263a]/60">
                    <%= length(tpl.workout_template_exercises || []) %> Übungen
                  </span>
                </button>
                <.link
                  navigate={~p"/templates/#{tpl.id}/edit"}
                  class="inline-flex min-h-[44px] min-w-[44px] shrink-0 items-center justify-center rounded-lg border-2 border-[#12263a] bg-transparent px-3 text-sm font-semibold text-[#12263a] hover:bg-[#12263a]/10"
                >
                  Bearbeiten
                </.link>
              </div>
              <div :if={@expanded_template_id == tpl.id} class="border-t border-[#c5d8d1] bg-[#f4edea]/80 px-4 py-3 pl-10">
                <ul class="space-y-1.5 text-sm text-[#12263a]/80">
                  <li :for={te <- (tpl.workout_template_exercises || [])} class="flex justify-between gap-2">
                    <span><%= te.exercise.name %></span>
                    <span class="text-[#12263a]/60"><%= index_exercise_subtitle(te) %></span>
                  </li>
                </ul>
                <p :if={tpl.workout_template_exercises == []} class="text-[#12263a]/50">Keine Übungen in diesem Template.</p>
              </div>
            </li>
          </ul>
          <p :if={@templates == []} class="px-4 py-8 text-center text-[#12263a]/60">
            Noch keine Templates. Klicke auf „Template anlegen“.
          </p>
        </div>
      <% end %>

      <%= if @live_action == :new do %>
        <.simple_form
          for={@form}
          id="template_form"
          phx-submit="save_template"
          phx-change="validate_template"
          class="rounded-lg border border-[#c5d8d1] bg-[#c5d8d1]/30 p-4"
        >
          <.input field={@form[:name]} type="text" label="Name des Templates" required />
          <:actions>
            <.button>Anlegen</.button>
            <.link navigate={~p"/templates"} class="inline-block">
              <.button type="button" variant="outline">Abbrechen</.button>
            </.link>
          </:actions>
        </.simple_form>
      <% end %>

      <%= if @live_action == :edit do %>
    <div class="mb-4">
      <.link navigate={~p"/templates"} class="text-sm text-[#06bcc1] hover:underline">← Zurück zur Liste</.link>
    </div>
    <form phx-submit="update_template_name" class="mb-4">
      <label for="template_name_edit" class="block text-sm font-semibold text-[#12263a]">Name des Templates</label>
      <div class="mt-1 flex gap-2">
        <input
          type="text"
          name="name"
          id="template_name_edit"
          value={@template.name}
          required
          class="block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
        />
        <button type="submit" class="shrink-0 rounded-lg border-2 border-[#12263a] bg-transparent px-3 font-semibold text-[#12263a] hover:bg-[#12263a]/10 min-h-[44px]">
          Speichern
        </button>
      </div>
    </form>
    <p class="mb-4 text-sm text-[#12263a]/70">
      Entweder Dauer (z. B. Dehnen 10 Min.) oder Sätze + Wiederholungen. Gewicht wird beim Workout eingegeben.
    </p>
    <div class="space-y-4">
      <.template_exercise_row
        :for={{te, idx} <- Enum.with_index(@template_exercises)}
        id={te.id}
        exercise_name={te.exercise.name}
        default_reps_min={te.default_reps_min}
        default_reps_max={te.default_reps_max}
        default_duration_seconds={te.default_duration_seconds}
        default_sets={te.default_sets}
        position={idx + 1}
        editing_exercise_id={@editing_exercise_id}
      />
    </div>
    <div class="mt-6">
      <.button phx-click="open_add_exercise">+ Übung hinzufügen</.button>
    </div>

    <div :if={@show_add_exercise} class="mt-6 rounded-lg border border-[#06bcc1] bg-[#c5d8d1]/30 p-4">
      <p class="mb-3 font-medium text-[#12263a]">Übung zum Template hinzufügen</p>
      <form phx-submit="add_exercise" class="space-y-3">
        <div>
          <label for="add_exercise_id" class="block text-sm font-semibold text-[#12263a]">Übung</label>
          <select
            id="add_exercise_id"
            name="exercise_id"
            required
            class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
          >
            <option value="">— wählen —</option>
            <option :for={ex <- @exercises} value={ex.id}><%= ex.name %></option>
          </select>
        </div>
        <p class="text-sm text-[#12263a]/70">
          Entweder Dauer (Min.) oder Sätze + Wdh. von/bis. Gewicht gibst du beim Workout ein.
        </p>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div>
            <label for="add_default_sets" class="block text-sm font-semibold text-[#12263a]">Sätze</label>
            <input
              type="number"
              name="default_sets"
              id="add_default_sets"
              min="1"
              value="1"
              class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
            />
          </div>
          <div>
            <label for="add_default_duration_min" class="block text-sm font-semibold text-[#12263a]">Dauer (Min.)</label>
            <input
              type="number"
              name="default_duration_min"
              id="add_default_duration_min"
              min="1"
              placeholder="z. B. 10"
              class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
            />
          </div>
          <div>
            <label for="add_default_reps_min" class="block text-sm font-semibold text-[#12263a]">Wdh. von</label>
            <input
              type="number"
              name="default_reps_min"
              id="add_default_reps_min"
              min="0"
              placeholder="z. B. 8"
              class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
            />
          </div>
          <div>
            <label for="add_default_reps_max" class="block text-sm font-semibold text-[#12263a]">Wdh. bis</label>
            <input
              type="number"
              name="default_reps_max"
              id="add_default_reps_max"
              min="0"
              placeholder="z. B. 12"
              class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
            />
          </div>
        </div>
        <div class="flex gap-2 pt-2">
          <.button>Hinzufügen</.button>
          <button type="button" phx-click="close_add_exercise" class="min-h-[44px] rounded-lg border-2 border-[#12263a] bg-transparent px-4 font-semibold text-[#12263a] hover:bg-[#12263a]/10">
            Abbrechen
          </button>
        </div>
      </form>
    </div>
      <% end %>
    </div>
    """
  end

  attr :id, :integer, required: true
  attr :exercise_name, :string, required: true
  attr :default_reps_min, :integer, default: nil
  attr :default_reps_max, :integer, default: nil
  attr :default_duration_seconds, :integer, default: nil
  attr :default_sets, :integer, default: nil
  attr :position, :integer, required: true
  attr :editing_exercise_id, :integer, default: nil

  defp template_exercise_row(assigns) do
    editing? = assigns.editing_exercise_id == assigns.id
    reps_range_text = reps_range_text(assigns.default_reps_min, assigns.default_reps_max)
    duration_text = duration_display(assigns.default_duration_seconds)
    subtitle_text = subtitle_text(duration_text, reps_range_text, assigns.default_sets)

    assigns =
      assigns
      |> assign(:editing?, editing?)
      |> assign(:reps_range_text, reps_range_text)
      |> assign(:duration_text, duration_text)
      |> assign(:subtitle_text, subtitle_text)

    ~H"""
    <div class="rounded-lg border border-[#c5d8d1] bg-[#c5d8d1]/20 p-4" id={"template-exercise-#{@id}"}>
      <div class="flex items-center justify-between">
        <span class="font-medium text-[#12263a]"><%= @position %>. <%= @exercise_name %></span>
        <div class="flex gap-2">
          <button
            :if={!@editing?}
            type="button"
            phx-click="edit_exercise"
            phx-value-id={@id}
            class="text-sm text-[#06bcc1] hover:underline"
          >
            Bearbeiten
          </button>
          <button
            type="button"
            phx-click="remove_exercise"
            phx-value-id={@id}
            class="text-sm text-rose-600 hover:underline"
          >
            Entfernen
          </button>
        </div>
      </div>
      <%= if @editing? do %>
        <form phx-submit="update_exercise" class="mt-3 space-y-3">
          <input type="hidden" name="template_exercise_id" value={@id} />
          <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div>
              <label for={"edit_sets_#{@id}"} class="block text-sm font-semibold text-[#12263a]">Sätze</label>
              <input
                type="number"
                name="default_sets"
                id={"edit_sets_#{@id}"}
                min="1"
                value={@default_sets || 1}
                class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
              />
            </div>
            <div>
              <label for={"edit_duration_#{@id}"} class="block text-sm font-semibold text-[#12263a]">Dauer (Min.)</label>
              <input
                type="number"
                name="default_duration_min"
                id={"edit_duration_#{@id}"}
                min="1"
                placeholder="z. B. 10"
                value={if @default_duration_seconds, do: div(@default_duration_seconds, 60), else: ""}
                class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
              />
            </div>
            <div>
              <label for={"edit_reps_min_#{@id}"} class="block text-sm font-semibold text-[#12263a]">Wdh. von</label>
              <input
                type="number"
                name="default_reps_min"
                id={"edit_reps_min_#{@id}"}
                min="0"
                placeholder="z. B. 8"
                value={@default_reps_min}
                class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
              />
            </div>
            <div>
              <label for={"edit_reps_max_#{@id}"} class="block text-sm font-semibold text-[#12263a]">Wdh. bis</label>
              <input
                type="number"
                name="default_reps_max"
                id={"edit_reps_max_#{@id}"}
                min="0"
                placeholder="z. B. 12"
                value={@default_reps_max}
                class="mt-1 block w-full rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] min-h-[44px]"
              />
            </div>
          </div>
          <div class="flex gap-2">
            <.button>Speichern</.button>
            <button type="button" phx-click="cancel_edit_exercise" class="min-h-[44px] rounded-lg border-2 border-[#12263a] bg-transparent px-4 font-semibold text-[#12263a] hover:bg-[#12263a]/10">
              Abbrechen
            </button>
          </div>
        </form>
      <% else %>
        <p class="mt-2 text-sm text-[#12263a]/70">
          <%= @subtitle_text %>
        </p>
      <% end %>
    </div>
    """
  end

  # Entweder "10 Min." (Zeit ersetzt Sätze) oder "8–12 Wdh. · 3 Sätze"
  defp subtitle_text(duration_text, _reps_range_text, _sets) when is_binary(duration_text), do: duration_text
  defp subtitle_text(_duration, reps_range_text, sets), do: "#{reps_range_text} · #{sets || 1} Sätze"

  defp index_exercise_subtitle(te) do
    case duration_display(te.default_duration_seconds) do
      nil -> "#{reps_range_text(te.default_reps_min, te.default_reps_max)} · #{te.default_sets || 1} Sätze"
      text -> text
    end
  end

  defp duration_display(nil), do: nil
  defp duration_display(sec) when is_integer(sec) and sec > 0 do
    min = div(sec, 60)
    if min == 1, do: "1 Min.", else: "#{min} Min."
  end

  defp reps_range_text(nil, nil), do: "– Wdh."
  defp reps_range_text(min, nil), do: "#{min}+ Wdh."
  defp reps_range_text(nil, max), do: "bis #{max} Wdh."
  defp reps_range_text(min, max) when min == max, do: "#{min} Wdh."
  defp reps_range_text(min, max), do: "#{min}–#{max} Wdh."

  def handle_event("toggle_template", %{"id" => id}, socket) do
    id = String.to_integer(id)
    new_expanded = if socket.assigns.expanded_template_id == id, do: nil, else: id
    {:noreply, assign(socket, :expanded_template_id, new_expanded)}
  end

  def handle_event("save_template", %{"workout_template" => params}, socket) do
    user_id = socket.assigns.current_user.id

    case WorkoutTemplates.create_workout_template(user_id, params) do
      {:ok, template} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/templates/#{template.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate_template", %{"workout_template" => params}, socket) do
    changeset =
      (socket.assigns.form_template || %WorkoutTemplate{})
      |> WorkoutTemplate.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("edit_exercise", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_exercise_id, String.to_integer(id))}
  end

  def handle_event("cancel_edit_exercise", _, socket) do
    {:noreply, assign(socket, :editing_exercise_id, nil)}
  end

  def handle_event("update_exercise", params, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    id = params["template_exercise_id"] |> String.to_integer()
    te = Enum.find(template.workout_template_exercises, &(&1.id == id))

    if te do
      duration_min = parse_int(params["default_duration_min"])
      default_duration_seconds = if duration_min && duration_min > 0, do: duration_min * 60, else: nil

      attrs = %{
        "default_sets" => parse_int(params["default_sets"]) || 1,
        "default_reps_min" => parse_int(params["default_reps_min"]),
        "default_reps_max" => parse_int(params["default_reps_max"]),
        "default_duration_seconds" => default_duration_seconds
      }

      case WorkoutTemplates.update_workout_template_exercise(te, attrs) do
        {:ok, _} ->
          template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, template.id)
          {:noreply,
           socket
           |> assign(:template, template)
           |> assign(:template_exercises, template.workout_template_exercises)
           |> assign(:editing_exercise_id, nil)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, assign(socket, :editing_exercise_id, nil)}
    end
  end

  def handle_event("remove_exercise", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    te = Enum.find(template.workout_template_exercises, &(to_string(&1.id) == id))
    if te, do: WorkoutTemplates.remove_exercise_from_template(te)

    template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, template.id)
    {:noreply,
     socket
     |> assign(:template, template)
     |> assign(:template_exercises, template.workout_template_exercises)
     |> assign(:editing_exercise_id, nil)}
  end

  def handle_event("open_add_exercise", _, socket) do
    {:noreply, assign(socket, :show_add_exercise, true)}
  end

  def handle_event("close_add_exercise", _, socket) do
    {:noreply, assign(socket, :show_add_exercise, false)}
  end

  def handle_event("update_template_name", %{"name" => name}, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template

    case WorkoutTemplates.update_workout_template(template, %{"name" => name}) do
      {:ok, _} ->
        template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, template.id)
        {:noreply,
         socket
         |> assign(:template, template)
         |> assign(:template_exercises, template.workout_template_exercises)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("add_exercise", params, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    next_position = length(socket.assigns.template_exercises)
    exercise_id = params["exercise_id"]

    duration_min = parse_int(params["default_duration_min"])
    default_duration_seconds = if duration_min && duration_min > 0, do: duration_min * 60, else: nil

    attrs = %{
      "position" => next_position,
      "default_sets" => parse_int(params["default_sets"]) || 1,
      "default_reps_min" => parse_int(params["default_reps_min"]),
      "default_reps_max" => parse_int(params["default_reps_max"]),
      "default_duration_seconds" => default_duration_seconds
    }

    case WorkoutTemplates.add_exercise_to_template(template.id, exercise_id, attrs) do
      {:ok, _} ->
        template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, template.id)
        {:noreply,
         socket
         |> assign(:template, template)
         |> assign(:template_exercises, template.workout_template_exercises)
         |> assign(:show_add_exercise, false)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp assign_form(socket, nil), do: assign(socket, :form, nil)

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "workout_template"))
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> nil
    end
  end

end
