defmodule MavuSnippetsUi.Live.Ce.CeInfoSnippet do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  # import Eigenart.EaHelpers, warn: false
  import Pit
  @impl true
  def render(original_assigns) do
    assigns = original_assigns.item |> AtomicMap.convert(safe: true, ignore: true)

    ~L"""
    <div class="ce-wrap <%= if assigns[:hidden] do %>opacity-30<% end %>">

      <div class="px-4 prose prose-xs">
      <%= if assigns[:text] do %><%= @text |> raw() %><% end %>
      </div>


    </div>

    """
  end
end
