defmodule GymRarWeb.PageController do
  use GymRarWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/exercises")
    else
      # Nur Root-Layout vom Router verwenden, kein zweites Layout (sonst Nav doppelt)
      render(conn, :home, layout: false)
    end
  end
end
