defmodule MavuSnippetsUi.Live.ContentElementComponent do
  use MavuSnippetsUiWeb, :live_component

  @impl true
  def render(assigns) do
    component_name = component_name_for_ctype(assigns.item["ctype"])

    ~L"""
    <div class="px-2 pt-6 pb-2 border border-gray-200 border-solid">
    <div class="absolute top-0 left-0 inline-block px-1 py-px text-xs text-white text-gray-500 bg-blue-200"><%= @item["ctype"] |> human_ctype() %></div>

    <div class="flex styleinfo">
      <span hidden class="p-1 text-xs text-gray-400 opacity-50 hover:opacity-100"><%= @item["classes_defaults"] %></span>
      <div hidden class="p-1 text-xs text-blue-500 truncate opacity-50 hover:opacity-100"><%= @item["classes"] %></div>
    </div>

        <%= if  module_exists?(component_name ) do %>
          <%= live_component @socket,
          component_name,
          item: @item,
          path: @path,
          snippet_group: @snippet_group,
          context: @context,
          mode: @mode

          %>
        <% else %>
          !! no component found for <%= @item["ctype"] %>
        <% end %>
    </div>
    """
  end

  def human_ctype(txt) do
    txt |> String.replace("ce_", "")
  end

  def component_name_for_ctype(ctype) when is_binary(ctype) do
    String.to_existing_atom("Elixir.MavuSnippetsUi.Live.Ce." <> Macro.camelize(ctype))
  end

  def module_exists?(module) do
    function_exported?(module, :__info__, 1)
  end
end
