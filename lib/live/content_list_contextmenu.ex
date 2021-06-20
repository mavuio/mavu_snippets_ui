defmodule MavuSnippetsUi.Live.ContentListContextmenu do
  @moduledoc false

  use MavuSnippetsUiWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> Phoenix.LiveView.assign(assigns)
     |> Phoenix.LiveView.assign(
       clipboard_size: (assigns.context.clipboard.(:get, nil) || []) |> length()
     )}
  end
end
