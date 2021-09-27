defmodule MavuSnippetsUi.Live.FileUploadComponent do
  @moduledoc false

  use MavuSnippetsUiWeb, :live_component

  @impl true
  def update(assigns, socket) do
    context = %{}

    img_classes =
      assigns[:img_classes]
      |> if_nil("object-cover w-full h-full bg-white object-cover w-full h-full bg-white")

    {:ok,
     socket
     |> Phoenix.LiveView.assign(assigns)
     |> Phoenix.LiveView.assign(:img_classes, img_classes)}
  end
end
