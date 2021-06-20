defmodule MavuSnippetsUi.Live.ListComponent do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  import MavuSnippetsUi, only: [get_conf_val: 2]
  require Ecto.Query

  def snippet_groups_module(assigns),
    do: assigns[:context][:snippets_ui_conf][:snippet_groups_module]

  @impl true
  def update(%{id: id, context: context} = assigns, socket) do
    items_query = snippet_groups_module(assigns).get_query(assigns, context)
    # first load
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       items_query: items_query,
       items_filtered:
         MavuList.process_list(
           items_query,
           id,
           listconf(assigns),
           socket.assigns[:items_filtered][:tweaks]
         )
     )}
  end

  def listconf(assigns) when is_map(assigns) do
    %{
      columns: [
        %{name: :id, label: "ID"},
        %{name: :path, label: "path"},
        %{name: :inserted_at, label: "created", type: :datetime}
      ],
      repo: get_conf_val(assigns[:context][:snippets_ui_conf], :repo),
      filter: &listfilter/3
    }
  end

  def listfilter(source, _conf, tweaks) do
    keyword = tweaks[:keyword]

    if MavuUtils.present?(keyword) do
      kwlike = "%#{keyword}%"

      source
      |> Ecto.Query.where(
        [o],
        ilike(o.path, ^kwlike)
      )
    else
      source
    end
  end

  def handle_event("add_item", _msg, socket) do
    {:noreply,
     socket
     |> push_patch(to: socket.assigns.base_path.(%{"rec" => "new"}))}
  end

  def handle_event("edit_item", %{"id" => rec_id}, socket) do
    {:noreply,
     socket
     |> push_patch(to: socket.assigns.base_path.(%{"rec" => rec_id}))}
  end

  def handle_event("delete_item", %{"id" => rec_id}, socket) do
    snippet_groups_module(socket.assigns).get_snippet_group(
      MavuUtils.to_int(rec_id),
      socket.assigns[:context][:snippets_ui_conf]
    )
    |> get_conf_val(socket.assigns[:context][:snippets_ui_conf], :repo).delete()

    {:noreply,
     socket
     |> push_redirect(to: socket.assigns.base_path.(%{}))}
  end

  @impl true
  def handle_event("list." <> event, msg, socket) do
    {:noreply,
     assign(socket,
       items_filtered:
         MavuList.handle_event(
           event,
           msg,
           socket.assigns.items_query,
           socket.assigns.items_filtered
         )
     )}
  end
end
