defmodule MavuSnippetsUi.Live.Ce.CeInfoSnippetEdit do
  @moduledoc false

  use MavuSnippetsUi.Live.Ce.CeEditBase
  use MavuSnippetsUiWeb, :live_component

  # import Eigenart.EaHelpers
  @impl true
  def update(%{celement: celement} = assigns, socket) do
    context = %{}

    socket =
      socket
      |> Phoenix.LiveView.assign(changeset: changeset_for_this_step(celement, context))

    super_update(assigns, socket)
  end

  @impl true
  def render(assigns) do
    ~L"""
        <div class="min-w-lg">
          <%= f = form_for @changeset, "#", as: :step_data, theme: :tw_default,phx_change: :validate, phx_submit: :save, phx_target: @myself, id: @id %>
          <div class="my-4 text-center">
            <button class="btn btn-primary" type="submit">Save</button>
          </div>
          <div class=""
          x-data={editor:null} x-init="editor = new MediumEditor('.editable');console.log('medium editor init',editor);">
          <%= input  f, :text,  using: :textarea, rows: 5 ,label: "Textp:",append_classes: "editable prose p-3 medium-editor-textarea"  %>
          </div>
          </form>
        </div>
    """
  end

  @impl true
  def changeset_for_this_step(values, _params) do
    data = %{}

    types =
      ~w(text)a
      |> Enum.map(&{&1, :string})
      |> Map.new()

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types), empty_values: [])

    # |> Ecto.Changeset.validate_length(:title,
    #   max: 10,
    #   message: "der Text darf nicht mehr als %{count} Zeichen haben"
    # )

    # |> required_error_messages(t(params, "msg.field_is_required"))
  end
end
