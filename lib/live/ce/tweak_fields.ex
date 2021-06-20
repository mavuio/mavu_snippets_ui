defmodule MavuSnippetsUi.Live.Ce.Components.TweakFields do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  def render(assigns) do
    ~L"""
    <%= input  @f, :slug,  label: "slug" %>
    """
  end
end
