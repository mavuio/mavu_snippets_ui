defmodule MavuSnippetsUi.Live.ContentEditComponent do
  use MavuSnippetsUiWeb, :live_component

  import MavuUtils

  alias MavuContent.Clist

  def update(assigns, socket) do
    celement = Clist.get_ce(assigns.contentlist, assigns.path, assigns.uid)

    edit_component_name = edit_component_name_for_ctype(celement["ctype"])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       celement: celement,
       component_id: "edit-#{assigns.uid}",
       edit_component_name: edit_component_name
     )}
  end

  def edit_component_name_for_ctype(ctype) when is_binary(ctype) do
    String.to_existing_atom("Elixir.MavuSnippetsUi.Live.Ce." <> Macro.camelize(ctype) <> "Edit")
  end

  def module_exists?(module) do
    function_exported?(module, :render, 1)
  end

  @impl true
  def handle_event("modal_hide", _, socket) do
    {:noreply,
     socket
     |> push_patch(to: return_path(socket))}
  end

  def return_path(socket) do
    socket.assigns.base_path.(%{})
  end
end
