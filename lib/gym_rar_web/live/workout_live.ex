defmodule GymRarWeb.WorkoutLive do
  use GymRarWeb, :live_view

  alias GymRar.Accounts
  alias GymRar.WorkoutTemplates
  alias GymRar.Workouts
  alias Phoenix.LiveView.JS

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case socket.assigns.live_action do
        :index ->
          templates = WorkoutTemplates.list_workout_templates_with_exercises(user_id)
          socket
          |> assign(:templates, templates)
          |> assign(:template, nil)
          |> assign(:rows, [])
          |> assign(:expanded_row_index, -1)
          |> assign(:history_open_row_index, nil)

        :archive ->
          workouts = Workouts.list_workouts(user_id)
          socket
          |> assign(:workouts, workouts)
          |> assign(:templates, [])
          |> assign(:template, nil)
          |> assign(:rows, [])

        :new ->
          template_id = params["template_id"]
          location_id =
            case params["location_id"] do
              id when is_binary(id) and id != "" -> String.to_integer(id)
              _ -> socket.assigns.current_user.current_workout_location_id
            end
          if template_id == nil || template_id == "" do
            socket
            |> put_flash(:error, "Bitte wähle ein Template.")
            |> push_navigate(to: ~p"/workouts")
          else
            template = WorkoutTemplates.get_workout_template_with_exercises!(user_id, template_id)
            locations = Workouts.list_locations(user_id)
            rows = build_rows(template, user_id, location_id)
            socket
            |> assign(:templates, [])
            |> assign(:template, template)
            |> assign(:locations, locations)
            |> assign(:location_id, location_id)
            |> assign(:new_location_name, "")
            |> assign(:rows, rows)
            |> assign(:expanded_row_index, 0)
            |> assign(:history_open_row_index, nil)
            |> assign(:editing_location, false)
          end
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="workout-live-root" class="mx-auto w-full max-w-4xl px-4" phx-hook="CloseHistoryModal">
      <%= if @live_action == :index do %>
        <.header class="mb-6">
          Workout
          <:subtitle>Template wählen und Workout starten</:subtitle>
        </.header>

        <.link navigate={~p"/dashboard"} class="mb-4 inline-block text-sm text-[#06bcc1] hover:underline">
          ← Start
        </.link>

        <div class="rounded-xl border border-[#c5d8d1] bg-[#f4edea]/50">
          <ul class="divide-y divide-[#c5d8d1]">
            <li :for={tpl <- @templates} class="flex items-center justify-between gap-2 px-4 py-3">
              <span class="font-medium text-[#12263a]"><%= tpl.name %></span>
              <span class="text-sm text-[#12263a]/60"><%= length(tpl.workout_template_exercises || []) %> Übungen</span>
              <.link
                navigate={~p"/workouts/new?template_id=#{tpl.id}"}
                class="inline-flex min-h-[44px] shrink-0 items-center justify-center rounded-lg bg-[#06bcc1] px-4 text-sm font-semibold text-[#12263a] hover:bg-[#06bcc1]/90"
              >
                Workout starten
              </.link>
            </li>
          </ul>
          <p :if={@templates == []} class="px-4 py-8 text-center text-[#12263a]/60">
            Keine Templates. Lege unter „Templates“ zuerst eine Vorlage an.
          </p>
        </div>
      <% else %>
      <%= if @live_action == :archive do %>
        <.header class="mb-6">
          Vergangene Workouts
          <:subtitle>Deine gespeicherten Workouts</:subtitle>
        </.header>

        <.link navigate={~p"/dashboard"} class="mb-4 inline-block text-sm text-[#06bcc1] hover:underline">
          ← Start
        </.link>

        <div class="rounded-xl border border-[#c5d8d1] bg-[#f4edea]/50">
          <ul class="divide-y divide-[#c5d8d1]">
            <li :for={w <- @workouts} class="flex flex-col gap-1 px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:gap-2">
              <div>
                <span class="font-medium text-[#12263a]"><%= w.name %></span>
                <p class="text-sm text-[#12263a]/60">
                  <%= format_date(w.performed_at) %><%= if w.workout_location, do: " · #{w.workout_location.name}", else: "" %>
                </p>
              </div>
              <span class="text-sm text-[#12263a]/60"><%= length(w.workout_exercises || []) %> Übungen</span>
            </li>
          </ul>
          <p :if={@workouts == []} class="px-4 py-8 text-center text-[#12263a]/60">
            Noch keine Workouts. Starte dein erstes über „Workout starten“.
          </p>
        </div>
      <% else %>
        <.header class="mb-6">
          Workout ausführen
          <:subtitle><%= @template.name %></:subtitle>
        </.header>

        <.link navigate={~p"/workouts"} class="mb-4 inline-block text-sm text-[#06bcc1] hover:underline">
          ← Zurück
        </.link>

        <% selected_location = Enum.find(@locations || [], &(&1.id == @location_id)) %>
        <div class="mb-3 flex w-full flex-wrap items-center gap-2 rounded-lg border border-[#c5d8d1]/60 bg-[#f4edea]/50 px-3 py-2">
          <span class="shrink-0 text-sm text-[#12263a]/70">Ort:</span>
          <%= if @editing_location do %>
            <form phx-change="set_location" class="flex min-w-0 flex-1 items-center gap-2">
              <select
                name="workout_location_id"
                class="min-h-[36px] min-w-0 flex-1 rounded border border-[#c5d8d1] bg-[#f4edea] px-2 py-1 text-sm text-[#12263a]"
              >
                <option value="">— wählen —</option>
                <option :for={loc <- @locations} value={loc.id} selected={@location_id == loc.id}><%= loc.name %></option>
              </select>
            </form>
            <form phx-submit="add_location" class="flex min-w-0 flex-1 items-center gap-1">
              <input type="text" name="new_location_name" value={@new_location_name} placeholder="Neu" class="min-h-[36px] min-w-0 flex-1 rounded border border-[#c5d8d1] bg-[#f4edea] px-2 py-1 text-sm text-[#12263a]" />
              <button type="submit" class="shrink-0 min-h-[36px] rounded border border-[#06bcc1] bg-[#06bcc1]/20 px-2 py-1 text-xs font-medium text-[#12263a]">+</button>
            </form>
            <button type="button" phx-click="toggle_edit_location" class="shrink-0 text-sm text-[#12263a]/70 underline">Fertig</button>
          <% else %>
            <span class="min-w-0 flex-1 text-sm font-medium text-[#12263a]"><%= if selected_location, do: selected_location.name, else: "—" %></span>
            <button type="button" phx-click="toggle_edit_location" class="shrink-0 text-sm text-[#06bcc1] underline">Bearbeiten</button>
          <% end %>
        </div>

        <form phx-submit="save_workout" phx-change="update_set_values" class="space-y-4">
          <div class="space-y-2">
            <.workout_row
              :for={{row, idx} <- Enum.with_index(@rows)}
              row={row}
              index={idx}
              expanded_row_index={@expanded_row_index}
              location_id={@location_id}
            />
          </div>
          <div class="flex flex-wrap gap-2 pt-4">
            <button
              type="submit"
              class="min-h-[44px] rounded-lg bg-[#12263a] px-4 py-2 font-semibold text-[#f4edea] hover:bg-[#12263a]/90"
            >
              Workout speichern
            </button>
            <.link
              navigate={~p"/workouts"}
              class="inline-flex min-h-[44px] items-center rounded-lg border-2 border-[#12263a] bg-transparent px-4 font-semibold text-[#12263a] hover:bg-[#12263a]/10"
            >
              Abbrechen
            </.link>
          </div>
        </form>

        <%= if @live_action == :new and @history_open_row_index != nil do %>
          <% history_row = Enum.at(@rows, @history_open_row_index) %>
          <.modal id="history-modal" show={true} on_cancel={JS.dispatch("close_history_modal")}>
            <div id="history-modal-content">
              <p class="mb-4 font-medium text-[#12263a]">
                Letzte Einträge: <%= if history_row, do: history_row.template_exercise.exercise.name, else: "" %><%= if @location_id, do: " (an diesem Ort)", else: "" %>
              </p>
              <%= if history_row && history_row[:history] != [] do %>
                <div class="mb-4 space-y-4">
                  <div :for={h <- history_row[:history]} class="rounded-lg border border-[#c5d8d1]/60 bg-[#f4edea]/50 p-3">
                    <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-[#12263a]/60">
                      <%= format_date(h.workout.performed_at) %>
                    </p>
                    <ul class="space-y-1.5 text-sm text-[#12263a]">
                      <li :for={{s, idx} <- Enum.with_index(h.sets)} class="flex items-baseline gap-2">
                        <span class="w-6 shrink-0 text-[#12263a]/50"><%= idx + 1 %>.</span>
                        <%= if s.skipped do %>
                          <span class="text-[#12263a]/60">übersprungen</span>
                        <% else %>
                          <span><%= if s.weight_kg, do: "#{s.weight_kg} kg", else: "–" %></span>
                          <span><%= if s.reps, do: "#{s.reps} Wdh.", else: "" %></span>
                          <span><%= if s.duration_seconds && s.duration_seconds > 0, do: "#{div(s.duration_seconds, 60)} Min.", else: "" %></span>
                        <% end %>
                      </li>
                    </ul>
                  </div>
                </div>
              <% else %>
                <p class="mb-4 text-[#12263a]/60">Noch keine vergangenen Workouts.</p>
              <% end %>
              <button type="button" phx-click="close_history_modal" class="rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-sm font-medium text-[#12263a] hover:bg-[#c5d8d1]/30">
                Schließen
              </button>
            </div>
          </.modal>
        <% end %>
      <% end %>
      <% end %>
    </div>
    """
  end

  attr :row, :map, required: true
  attr :index, :integer, required: true
  attr :expanded_row_index, :integer, required: true
  attr :location_id, :integer, default: nil

  defp workout_row(assigns) do
    te = assigns.row.template_exercise
    is_duration = te.default_duration_seconds != nil
    target_text = target_text(te)
    expanded? = assigns.expanded_row_index == assigns.index

    assigns =
      assigns
      |> assign(:exercise_name, te.exercise.name)
      |> assign(:is_duration, is_duration)
      |> assign(:target_text, target_text)
      |> assign(:expanded?, expanded?)

    ~H"""
    <div class="rounded-xl border border-[#c5d8d1] bg-[#c5d8d1]/20 overflow-hidden">
      <button
        type="button"
        phx-click="toggle_row"
        phx-value-index={@index}
        class="flex min-h-[48px] w-full items-center justify-between gap-2 px-4 py-3 text-left"
      >
        <span class="font-medium text-[#12263a]"><%= @index + 1 %>. <%= @exercise_name %></span>
        <span class="hidden shrink-0 text-sm text-[#12263a]/60 sm:inline"><%= @target_text %></span>
        <span class={["shrink-0 transition-transform", @expanded? && "rotate-90"]}>▶</span>
      </button>
      <div :if={@expanded?} class="border-t border-[#c5d8d1] bg-[#f4edea]/80 px-3 py-3 sm:px-4">
        <div class="mb-3 flex flex-wrap items-center gap-2">
          <span class="text-sm text-[#12263a]/70"><%= @target_text %></span>
          <button
            type="button"
            phx-click="open_history_modal"
            phx-value-index={@index}
            class="text-sm text-[#12263a]/70 underline decoration-[#06bcc1]/50 hover:text-[#06bcc1] hover:decoration-[#06bcc1]"
          >
            Letzte Workouts
          </button>
        </div>
        <div class="space-y-3">
          <div
            :for={{set, set_idx} <- Enum.with_index(@row.sets)}
            class="flex w-full flex-wrap items-center gap-2 rounded-lg border border-[#c5d8d1]/50 bg-white/60 p-2 sm:p-3"
          >
            <span class="w-10 shrink-0 text-sm font-medium text-[#12263a]/70">Satz <%= set_idx + 1 %></span>
            <div class="flex min-h-[44px] min-w-0 flex-1 items-center gap-1 rounded-lg border border-[#c5d8d1] bg-[#f4edea] pl-2 pr-1">
              <.icon name="hero-scale-solid" class="h-4 w-4 shrink-0 text-[#12263a]/50" />
              <input
                type="number"
                name={"row_#{@index}_set_#{set_idx}_weight_kg"}
                id={"weight_#{@index}_#{set_idx}"}
                value={set["weight_kg"]}
                step="0.5"
                min="0"
                placeholder="kg"
                class="min-w-0 flex-1 border-0 bg-transparent py-2 pl-1 pr-2 text-[#12263a] focus:ring-0"
              />
            </div>
            <%= if @is_duration do %>
              <div class="flex min-h-[44px] min-w-0 flex-1 items-center gap-1 rounded-lg border border-[#c5d8d1] bg-[#f4edea] pl-2 pr-1">
                <.icon name="hero-clock-solid" class="h-4 w-4 shrink-0 text-[#12263a]/50" />
                <input
                  type="number"
                  name={"row_#{@index}_set_#{set_idx}_duration_seconds"}
                  id={"duration_#{@index}_#{set_idx}"}
                  value={duration_display_input(set["duration_seconds"])}
                  min="0"
                  placeholder="Min"
                  class="min-w-0 flex-1 border-0 bg-transparent py-2 pl-1 pr-2 text-[#12263a] focus:ring-0"
                />
              </div>
            <% else %>
              <div class="flex min-h-[44px] min-w-0 flex-1 items-center gap-1 rounded-lg border border-[#c5d8d1] bg-[#f4edea] pl-2 pr-1">
                <.icon name="hero-hashtag-solid" class="h-4 w-4 shrink-0 text-[#12263a]/50" />
                <input
                  type="number"
                  name={"row_#{@index}_set_#{set_idx}_reps"}
                  id={"reps_#{@index}_#{set_idx}"}
                  value={set["reps"]}
                  min="0"
                  placeholder="Wdh"
                  class="min-w-0 flex-1 border-0 bg-transparent py-2 pl-1 pr-2 text-[#12263a] focus:ring-0"
                />
              </div>
            <% end %>
            <label class="flex min-h-[44px] shrink-0 cursor-pointer items-center gap-1.5 rounded-lg border border-[#c5d8d1]/50 bg-[#f4edea]/60 px-2 py-1.5 text-[#12263a]/80" title="übersprungen">
              <input
                type="checkbox"
                name={"row_#{@index}_set_#{set_idx}_skipped"}
                checked={set["skipped"]}
                value="true"
                class="h-4 w-4 rounded border-[#c5d8d1]"
              />
              <.icon name="hero-minus-circle-solid" class="h-4 w-4 shrink-0 text-[#12263a]/50" />
            </label>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp format_date(date) do
    Calendar.strftime(date, "%d.%m.%Y")
  end

  defp target_text(te) do
    if te.default_duration_seconds && te.default_duration_seconds > 0 do
      min = div(te.default_duration_seconds, 60)
      if min == 1, do: "1 Min.", else: "#{min} Min."
    else
      reps = reps_range_text(te.default_reps_min, te.default_reps_max)
      sets = te.default_sets || 1
      "#{reps} · #{sets} Sätze"
    end
  end

  defp reps_range_text(nil, nil), do: "– Wdh."
  defp reps_range_text(min, nil), do: "#{min}+ Wdh."
  defp reps_range_text(nil, max), do: "bis #{max} Wdh."
  defp reps_range_text(min, max) when min == max, do: "#{min} Wdh."
  defp reps_range_text(min, max), do: "#{min}–#{max} Wdh."

  defp duration_display_input(nil), do: ""
  defp duration_display_input(""), do: ""
  defp duration_display_input(sec) when is_integer(sec) and sec > 0, do: to_string(div(sec, 60))
  # Im Row-State speichern wir Minuten als String (vom Input); nur bei Save rechnen wir in Sekunden um.
  defp duration_display_input(sec) when is_binary(sec) do
    case Integer.parse(sec) do
      {min, _} -> to_string(min)
      :error -> ""
    end
  end
  defp duration_display_input(_), do: ""

  defp build_rows(template, user_id, location_id) do
    template.workout_template_exercises
    |> Enum.map(fn te ->
      num_sets = te.default_sets || 1
      default_duration_min = if te.default_duration_seconds && te.default_duration_seconds > 0, do: to_string(div(te.default_duration_seconds, 60)), else: ""

      sets =
        for _ <- 1..num_sets do
          %{
            "weight_kg" => "",
            "reps" => "",
            "duration_seconds" => default_duration_min,
            "skipped" => false
          }
        end

      history = Workouts.exercise_history(user_id, te.exercise_id, 3, location_id)
      %{template_exercise: te, sets: sets, history: history}
    end)
  end

  defp rebuild_rows_keep_sets(template, user_id, location_id, current_rows) do
    new_rows = build_rows(template, user_id, location_id)
    Enum.zip(current_rows, new_rows)
    |> Enum.map(fn {cur, new} -> %{new | sets: cur.sets} end)
  end

  defp params_to_rows(params, rows) do
    Enum.with_index(rows)
    |> Enum.map(fn {row, row_idx} ->
      sets =
        row.sets
        |> Enum.with_index()
        |> Enum.map(fn {set, set_idx} ->
          prefix = "row_#{row_idx}_set_#{set_idx}_"
          %{
            "weight_kg" => params[prefix <> "weight_kg"] || set["weight_kg"] || "",
            "reps" => params[prefix <> "reps"] || set["reps"] || "",
            "duration_seconds" => params[prefix <> "duration_seconds"] || set["duration_seconds"] || "",
            "skipped" => params[prefix <> "skipped"] == "true"
          }
        end)

      Map.put(row, :sets, sets)
    end)
  end

  def handle_event("toggle_edit_location", _, socket) do
    {:noreply, assign(socket, :editing_location, !socket.assigns.editing_location)}
  end

  def handle_event("set_location", %{"workout_location_id" => ""}, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    rows = rebuild_rows_keep_sets(template, user_id, nil, socket.assigns.rows)
    {:noreply,
     socket
     |> assign(:location_id, nil)
     |> assign(:rows, rows)
     |> assign(:editing_location, false)}
  end

  def handle_event("set_location", %{"workout_location_id" => id}, socket) when is_binary(id) and id != "" do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    location_id = String.to_integer(id)
    rows = rebuild_rows_keep_sets(template, user_id, location_id, socket.assigns.rows)
    {:noreply,
     socket
     |> assign(:location_id, location_id)
     |> assign(:rows, rows)
     |> assign(:editing_location, false)}
  end

  def handle_event("add_location", %{"new_location_name" => name}, socket) when is_binary(name) do
    name = String.trim(name)
    if name == "" do
      {:noreply, socket}
    else
      user_id = socket.assigns.current_user.id
      template = socket.assigns.template
      case Workouts.create_location(user_id, %{"name" => name}) do
        {:ok, location} ->
          locations = Workouts.list_locations(user_id)
          rows = rebuild_rows_keep_sets(template, user_id, location.id, socket.assigns.rows)
          {:noreply,
           socket
           |> assign(:locations, locations)
           |> assign(:location_id, location.id)
           |> assign(:new_location_name, "")
           |> assign(:rows, rows)}
        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Ort konnte nicht angelegt werden (evtl. schon vorhanden).")}
      end
    end
  end

  def handle_event("add_location", _params, socket), do: {:noreply, socket}

  def handle_event("toggle_row", %{"index" => idx}, socket) do
    idx = String.to_integer(idx)
    new_expanded = if socket.assigns.expanded_row_index == idx, do: -1, else: idx
    {:noreply, assign(socket, :expanded_row_index, new_expanded)}
  end

  def handle_event("open_history_modal", %{"index" => idx}, socket) do
    {:noreply, assign(socket, :history_open_row_index, String.to_integer(idx))}
  end

  def handle_event("close_history_modal", _, socket) do
    {:noreply, assign(socket, :history_open_row_index, nil)}
  end

  def handle_event("update_set_values", params, socket) do
    rows = params_to_rows(params, socket.assigns.rows)
    {:noreply, assign(socket, :rows, rows)}
  end

  def handle_event("save_workout", params, socket) do
    if socket.assigns.location_id == nil do
      {:noreply,
       socket
       |> put_flash(:error, "Bitte zuerst einen Ort (Gym) wählen.")}
    else
      save_workout_impl(params, socket)
    end
  end

  defp save_workout_impl(params, socket) do
    user_id = socket.assigns.current_user.id
    template = socket.assigns.template
    rows = socket.assigns.rows
    location_id = socket.assigns.location_id

    rows_data =
      Enum.with_index(rows)
      |> Enum.map(fn {row, row_idx} ->
        sets =
          row.sets
          |> Enum.with_index()
          |> Enum.map(fn {_set, set_idx} ->
            prefix = "row_#{row_idx}_set_#{set_idx}_"
            weight_kg = params[prefix <> "weight_kg"]
            reps = params[prefix <> "reps"]
            duration_seconds = params[prefix <> "duration_seconds"]
            skipped = params[prefix <> "skipped"] == "true"

            duration_sec =
              if duration_seconds != nil && duration_seconds != "" do
                case Integer.parse(duration_seconds) do
                  {min, _} -> min * 60
                  :error -> nil
                end
              else
                nil
              end

            %{
              "weight_kg" => weight_kg,
              "reps" => reps,
              "duration_seconds" => duration_sec,
              "skipped" => skipped
            }
          end)

        %{
          "template_exercise_id" => row.template_exercise.id,
          "sets" => sets
        }
      end)

    case Workouts.create_workout_from_template(user_id, template, rows_data, location_id) do
      {:ok, _workout} ->
        if location_id, do: Accounts.update_user_current_location(socket.assigns.current_user, location_id)
        {:noreply,
         socket
         |> put_flash(:info, "Workout gespeichert.")
         |> push_navigate(to: ~p"/workouts")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Speichern fehlgeschlagen.")
         |> push_navigate(to: ~p"/workouts")}
    end
  end
end
