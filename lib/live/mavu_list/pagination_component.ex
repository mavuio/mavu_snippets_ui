defmodule MavuSnippetsUi.Live.MavuList.PaginationComponent do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  @impl true
  def update(%{list: list} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(MavuList.generate_assigns_for_pagination_component(list))

    {:ok, socket}
  end
end
