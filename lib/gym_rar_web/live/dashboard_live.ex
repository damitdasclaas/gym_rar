defmodule GymRarWeb.DashboardLive do
  use GymRarWeb, :live_view

  alias GymRar.Accounts
  alias GymRar.Workouts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_id = user.id
    current_location = Workouts.get_location(user_id, user.current_workout_location_id)
    locations = Workouts.list_locations(user_id)

    {:ok,
     socket
     |> assign(:current_location, current_location)
     |> assign(:locations, locations)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header class="mb-6">
        Start
        <:subtitle>Dein Überblick</:subtitle>
      </.header>

      <div class="rounded-xl border border-[#c5d8d1] bg-[#f4edea]/60 p-3 sm:p-4">
        <p class="mb-2 text-sm font-medium text-[#12263a]/70">Aktuelles Gym</p>
        <form phx-change="set_current_location" class="flex flex-wrap items-center gap-2">
          <select
            name="current_workout_location_id"
            class="min-h-[40px] max-w-[16rem] rounded-lg border border-[#c5d8d1] bg-[#f4edea] px-3 py-2 text-[#12263a] text-sm"
          >
            <option value="">— Ort wählen —</option>
            <option
              :for={loc <- @locations}
              value={loc.id}
              selected={@current_location && @current_location.id == loc.id}
            >
              <%= loc.name %>
            </option>
          </select>
        </form>
        <p class="mt-1.5 text-xs text-[#12263a]/60">
          Wird beim Workout vorausgewählt. Hier änderbar, falls du woanders trainierst.
        </p>
      </div>

      <div class="grid gap-3 sm:grid-cols-2">
        <.link
          navigate={~p"/workouts"}
          class="flex min-h-[56px] items-center justify-center rounded-xl border-2 border-[#06bcc1] bg-[#06bcc1]/15 px-4 py-3 text-center font-semibold text-[#12263a] hover:bg-[#06bcc1]/25"
        >
          Workout starten
        </.link>
        <.link
          navigate={~p"/templates"}
          class="flex min-h-[56px] items-center justify-center rounded-xl border-2 border-[#c5d8d1] bg-[#f4edea] px-4 py-3 text-center font-semibold text-[#12263a] hover:bg-[#c5d8d1]/50"
        >
          Workout-Templates
        </.link>
        <.link
          navigate={~p"/exercises"}
          class="flex min-h-[56px] items-center justify-center rounded-xl border-2 border-[#c5d8d1] bg-[#f4edea] px-4 py-3 text-center font-semibold text-[#12263a] hover:bg-[#c5d8d1]/50"
        >
          Übungen
        </.link>
        <.link
          navigate={~p"/workouts/archive"}
          class="flex min-h-[56px] items-center justify-center rounded-xl border-2 border-[#c5d8d1] bg-[#f4edea] px-4 py-3 text-center font-semibold text-[#12263a] hover:bg-[#c5d8d1]/50"
        >
          Vergangene Workouts
        </.link>
      </div>
    </div>
    """
  end

  def handle_event("set_current_location", %{"current_workout_location_id" => ""}, socket) do
    user = socket.assigns.current_user
    case Accounts.update_user_current_location(user, nil) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:current_location, nil)}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("set_current_location", %{"current_workout_location_id" => id}, socket) when is_binary(id) and id != "" do
    user = socket.assigns.current_user
    location_id = String.to_integer(id)
    case Accounts.update_user_current_location(user, location_id) do
      {:ok, updated_user} ->
        current_location = Workouts.get_location(user.id, location_id)
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:current_location, current_location)}
      {:error, _} ->
        {:noreply, socket}
    end
  end
end
