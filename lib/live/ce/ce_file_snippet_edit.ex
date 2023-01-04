defmodule MavuSnippetsUi.Live.Ce.CeFileSnippetEdit do
  @moduledoc false

  use MavuSnippetsUi.Live.Ce.CeEditBase
  use MavuSnippetsUiWeb, :live_component

  import MavuUtils, only: [pipe_when: 3]

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> allow_upload(:filename_l1, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l2, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l3, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l4, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l5, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l6, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l7, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l8, accept: :any, dest: "/snippet_files")
      |> allow_upload(:filename_l9, accept: :any, dest: "/snippet_files")
      |> Phoenix.Component.assign(
        active_language_map:
          get_active_language_map(
            assigns.context.active_langs,
            assigns.context[:snippets_conf]
          )
      )

    super_update(assigns, socket)
  end

  @impl true
  def changeset_for_this_step(values, params) do
    data = %{}

    # types =
    #   ~w(name url visible image)a
    #   |> Enum.map(&{&1, :string})
    #   |> Map.new()

    # {data, types}
    # |> Ecto.Changeset.cast(values, Map.keys(types))
    # |> Ecto.Changeset.validate_required(~w(name)a)
    # |> validate_url(:url)

    types =
      ~w(filename_l1 filename_l2 filename_l3 filename_l4 filename_l5 filename_l6 filename_l7 filename_l8 filename_l9 slug)a
      |> Enum.map(&{&1, :string})
      |> Map.new()

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types), empty_values: [])
  end

  def validate_url(changeset, field, opts \\ []) do
    Ecto.Changeset.validate_change(changeset, field, fn _, value ->
      if value == "" do
        []
      else
        case URI.parse(value) do
          %URI{scheme: nil} ->
            "is missing a scheme (e.g. https)"

          %URI{host: nil} ->
            "is missing a host"

          %URI{host: host} ->
            case :inet.gethostbyname(Kernel.to_charlist(host)) do
              {:ok, _} -> nil
              {:error, _} -> "invalid host"
            end
        end
        |> case do
          error when is_binary(error) -> [{field, Keyword.get(opts, :message, error)}]
          _ -> []
        end
      end
    end)
  end

  # attachment handling --- start
  def handle_event("validate" = event, msg, socket) do
    socket =
      get_upload_fields(socket)
      |> Enum.reduce(socket, &remove_other_uploads/2)

    super_handle_event(event, msg, socket)
  end

  def handle_event("remove_attachment", %{"field" => field}, socket)
      when is_binary(field) do
    field = String.to_existing_atom(field)
    changed_values = %{"step_data" => socket.assigns.changeset.changes |> Map.put(field, "_")}
    super_handle_event("validate", changed_values, socket)
  end

  def handle_event("cancel_upload", %{"field" => field, "ref" => ref}, socket) do
    field = String.to_existing_atom(field)
    {:noreply, Phoenix.LiveView.cancel_upload(socket, field, ref)}
  end

  def handle_event("save", %{"step_data" => incoming_data}, socket) do
    {socket, incoming_data} =
      get_upload_fields(socket)
      |> Enum.reduce({socket, incoming_data}, fn field, {socket, incoming_data} ->
        {socket, put_attachment_url(socket, incoming_data, field)}
      end)

    save_step_data(incoming_data, socket)
  end

  @impl true
  def get_attachment_filename(socket, field, entry)
      when is_atom(field) and is_map(entry) do
    socket.assigns |> IO.inspect(label: "mwuits-debug 2021-09-27_19:33 ")

    lang_addon =
      case field do
        :filename_l1 -> ""
        field -> String.replace_prefix("#{field}", "filename_", "_")
      end

    "#{socket.assigns.snippet_group.path |> String.replace("/", "_")}-#{socket.assigns.celement["slug"] |> String.replace_suffix("_file", "")}#{lang_addon}.#{attachment_ext(entry)}"
  end

  # attachment handling --- end

  def get_active_language_map(active_langs, conf \\ %{}) when is_list(active_langs) do
    active_langs
    |> Enum.map(fn lang ->
      langnum = MavuSnippets.langnum_for_langstr(lang, conf)

      %{
        lang: lang,
        langnum: langnum,
        fieldname: "filename_l#{langnum}" |> String.to_existing_atom()
      }
    end)
  end
end
