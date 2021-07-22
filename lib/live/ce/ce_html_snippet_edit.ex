defmodule MavuSnippetsUi.Live.Ce.CeHtmlSnippetEdit do
  @moduledoc false

  use MavuSnippetsUi.Live.Ce.CeEditBase
  use MavuSnippetsUiWeb, :live_component

  # importMavuUtils
  @impl true

  def update(assigns, socket) do
    socket =
      socket
      |> Phoenix.LiveView.assign(
        active_language_map:
          get_active_language_map(
            assigns.context.active_langs,
            assigns.context[:snippets_conf]
          )
      )

    super_update(assigns, socket)
  end

  @impl true
  def changeset_for_this_step(values, _params) do
    data = %{}

    types =
      ~w(text_l1 text_l2 text_l3 text_l4 text_l5 text_l6 text_l7 text_l8 text_l9 slug)a
      |> Enum.map(&{&1, :string})
      |> Map.new()

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types), empty_values: [])
  end

  def get_active_language_map(active_langs, conf \\ %{}) when is_list(active_langs) do
    active_langs
    |> Enum.map(fn lang ->
      langnum = MavuSnippets.langnum_for_langstr(lang, conf)

      %{
        lang: lang,
        langnum: langnum,
        fieldname: "text_l#{langnum}" |> String.to_existing_atom()
      }
    end)
  end
end
