defmodule MavuSnippetsUi.Live.Ce.CeTextSnippet do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  # import Eigenart.EaHelpers, warn: false
  import Pit
  @impl true
  def render(original_assigns) do
    assigns = original_assigns.item |> AtomicMap.convert(safe: true, ignore: true)

    ~L"""
    <div class="ce-wrap <%= if assigns[:hidden] do %>opacity-30<% end %>">

    <div class="flex p-4 divide-x divide-gray-600 divide-dashed min-w-md">
      <div class="w-1/2 px-4 prose prose-xs">
      <%= if assigns[:text_l1] do %><%= @text_l1 |>  text_to_html()  %><% end %>
      </div>
      <div class="hidden w-1/2 px-4 prose prose-xs">
      <%= if assigns[:text_l2] do %><%= @text_l2 |>  text_to_html()  %><% end %>
      </div>
    </div>

    </div>

    """
  end
end
