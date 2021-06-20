defmodule MavuSnippetsUi.Live.Ce.CeHtmlSnippetEdit do
  @moduledoc false

  use MavuSnippetsUi.Live.Ce.CeEditBase
  use MavuSnippetsUiWeb, :live_component

  # import Eigenart.EaHelpers
  @impl true
  def update(%{celement: celement} = assigns, socket) do
    context = %{}

    socket =
      socket
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), dest: "/ce_files")
      #  |> allow_upload(:download, accept: ~w(.pdf .doc .docx))
      |> Phoenix.LiveView.assign(changeset: changeset_for_this_step(celement, context))

    super_update(assigns, socket)
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

    # |> Ecto.Changeset.validate_length(:title,
    #   max: 10,
    #   message: "der Text darf nicht mehr als %{count} Zeichen haben"
    # )

    # |> required_error_messages(t(params, "msg.field_is_required"))
  end
end
