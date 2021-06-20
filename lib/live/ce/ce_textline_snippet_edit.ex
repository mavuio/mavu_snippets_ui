defmodule MavuSnippetsUi.Live.Ce.CeTextlineSnippetEdit do
  @moduledoc false

  use MavuSnippetsUi.Live.Ce.CeEditBase
  use MavuSnippetsUiWeb, :live_component

  # import Eigenart.EaHelpers
  @impl true
  def update(%{celement: celement} = assigns, socket) do
    context = %{}

    assigns |> IO.inspect(label: "CeTextlineSnippetEdit assigns ")

    socket =
      socket
      |> Phoenix.LiveView.assign(changeset: changeset_for_this_step(celement, context))

    super_update(assigns, socket)
  end

  @impl true
  def render(assigns) do
    assigns |> IO.inspect(label: "CeTextlineSnippetEdit render ")

    ~L"""
        <%= f = form_for @changeset, "#", as: :step_data, theme: :tw_default,phx_change: :validate, phx_submit: :save, phx_target: @myself, id: @id, class: "w-lg" %>

        <div class="my-4 text-center">
          <button class="btn btn-primary" type="submit">Save</button>
        </div>

        <%= if @conf[:mode] == :tweak do  %>
         <%= live_component @socket, MavuSnippetsUi.Live.Ce.Components.TweakFields , f: f %>
        <% end %>


        <%= input  f, :text_l1,  using: :text_input, rows: 5 ,label: "Text:"  %>
        <%#= input  f, :text_l2,  class: "hidden", using: :text_input, rows: 5 ,label: "Text [DE]:", placeholder: f.params["text_l1"]  %>




        </form>
    """
  end

  @impl true
  def changeset_for_this_step(values, _params) do
    data = %{}

    types =
      ~w(text_l2 text_l1 slug)a
      |> Enum.map(&{&1, :string})
      |> Map.new()

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types), empty_values: [])
  end
end