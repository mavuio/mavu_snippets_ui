defmodule MavuSnippetsUi.Live.Ce.CeEditBase do
  @moduledoc "Boilerplate for Ce-Edit-Component"

  # @callback process(Plug.Conn.t(), map()) :: Plug.Conn.t()

  @callback changeset_for_this_step(
              Ecto.Schema.t()
              | Ecto.Changeset.t()
              | {Ecto.Changeset.data(), Ecto.Changeset.types()},
              map()
            ) ::
              Ecto.Schema.t()
              | Ecto.Changeset.t()
              | {Ecto.Changeset.data(), Ecto.Changeset.types()}

  @callback get_attachment_basepath(
              socket :: Phoenix.Socket.t(),
              field :: atom(),
              entry :: Phoenix.LiveView.UploadEntry.t()
            ) :: binary()
  @callback get_attachment_url(
              socket :: Phoenix.Socket.t(),
              field :: atom(),
              entry :: Phoenix.LiveView.UploadEntry.t()
            ) ::
              binary()
  @callback get_attachment_storage_path(
              socket :: Phoenix.Socket.t(),
              field :: atom(),
              entry :: Phoenix.LiveView.UploadEntry.t()
            ) :: binary()
  @callback get_attachment_filename(
              socket :: Phoenix.Socket.t(),
              field :: atom(),
              entry :: Phoenix.LiveView.UploadEntry.t()
            ) :: binary()

  @callback save_step_data(
              field :: map(),
              socket :: Phoenix.Socket.t()
            ) ::
              {atom(), Phoenix.Socket.t()}
              | {atom(), Phoenix.LiveView.Socket.t()}

  @optional_callbacks changeset_for_this_step: 2,
                      get_attachment_basepath: 3,
                      get_attachment_url: 3,
                      get_attachment_storage_path: 3,
                      get_attachment_filename: 3,
                      save_step_data: 2

  # , process: 2

  # https://stackoverflow.com/questions/39490972/adding-default-handle-info-in-using-macro
  defmacro(__using__(_)) do
    quote do
      # @checkout_key "checkout"
      @behaviour MavuSnippetsUi.Live.Ce.CeEditBase
      @before_compile MavuSnippetsUi.Live.Ce.CeEditBase

      import Pit
      import MavuUtils

      def super_update(%{celement: celement} = assigns, socket) do
        context = %{}

        {:ok,
         socket
         |> Phoenix.LiveView.assign(assigns)
         |> Phoenix.LiveView.assign(
           changeset:
             changeset_for_this_step(
               celement |> fill_with_defaults(socket.assigns, context),
               context
             ),
           next_action: :keep_editing
         )}
      end

      def fill_with_defaults(
            celement,
            %{active_language_map: active_language_map} = assigns,
            _context
          )
          when is_map(celement) and is_map(assigns) do
        active_language_map
        |> Enum.reduce(celement, fn %{langnum: langnum}, celement ->
          fill_element_with_default(celement, langnum)
        end)
      end

      def fill_with_defaults(celement, _assigns, _context), do: celement

      def fill_element_with_default(celement, langnum)
          when is_map(celement) and is_integer(langnum) do
        if MavuUtils.empty?(celement["text_l#{langnum}"]) do
          celement |> Map.put("text_l#{langnum}", celement["text_d#{langnum}"])
        else
          celement
        end
        |> IO.inspect(label: "mwuits-debug 2021-07-22_12:11 FILL #{langnum}")
      end

      def super_handle_event("validate", %{"step_data" => incoming_data} = msg, socket) do
        msg |> log("editor received validate event", :debug)

        changeset =
          changeset_for_this_step(incoming_data, socket.assigns)
          |> Map.put(:action, :insert)

        {:noreply, Phoenix.LiveView.assign(socket, changeset: changeset)}
      end

      def super_handle_event("close_on_save", msg, socket) do
        msg |> log("editor close_on_save event", :debug)

        {:noreply, socket |> Phoenix.LiveView.assign(next_action: :close)}
      end

      def super_handle_event("save", %{"step_data" => incoming_data} = msg, socket) do
        msg |> log("editor received save event", :info)
        save_step_data(incoming_data, socket)
      end

      def super_handle_event("save", msg, socket) do
        msg |> log("editor received empty save event", :info)
        save_step_data(%{}, socket)
      end

      def super_handle_event(event, msg, socket) do
        {event, msg} |> log("editor received unknown event", :error)
        {:noreply, socket}
      end

      def super_save_step_data(%{"__next_action" => next_action} = incoming_data, socket),
        do:
          super_save_step_data(
            Map.drop(incoming_data, ["__next_action"]),
            Phoenix.LiveView.assign(socket, next_action: String.to_existing_atom(next_action))
          )

      def super_save_step_data(incoming_data, socket) do
        # {incoming_data, socket.assigns}
        # |> IO.inspect(label: "mwuits-debug 2020-12-18_12:07 super_save_step_data")

        changeset_for_this_step(incoming_data, socket.assigns)
        |> Ecto.Changeset.apply_action(:update)
        |> case do
          {:ok, clean_incoming_data} ->
            clean_incoming_data |> IO.inspect(label: "clean_incoming_data")

            socket.assigns
            |> pit!(el <- %{celement: el})
            |> update_celement(clean_incoming_data)
            |> send_updated_celement_to_parent(socket.assigns)

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, Phoenix.LiveView.assign(socket, changeset: changeset)}
        end
      end

      def changeset_for_this_step(values, context) do
        data = %{}
        types = %{}

        {data, types}
        |> Ecto.Changeset.cast(values, Map.keys(types))
      end

      def update_celement(celement, changes) when is_map(celement) and is_map(changes) do
        celement
        |> Map.merge(MavuContent.Ce.stringify_keys(changes))
      end

      def send_updated_celement_to_parent(celement, %{uid: uid, path: path} = assigns)
          when is_map(celement) do
        next_action = assigns[:next_action] || :close

        send(
          self(),
          {:mavu_snippets_ui_msg,
           {:update_ce, %{uid: uid, path: path, data: celement}, next_action}}
        )
      end

      # attachment handling:

      def remove_other_uploads(field, socket) when is_atom(field) do
        case socket.assigns.uploads[field].entries do
          [_ | _] = entries ->
            [_new_entry | rest_entrys] =
              entries
              |> Enum.map(& &1.ref)
              |> Enum.reverse()

            rest_entrys
            |> Enum.reduce(socket, fn ref, socket ->
              Phoenix.LiveView.cancel_upload(socket, field, ref)
            end)

          _ ->
            socket
        end
      end

      def get_upload_fields(socket) do
        socket.assigns[:uploads]
        |> if_nil(%{})
        |> Map.drop([:__phoenix_refs_to_names__])
        |> Map.keys()
      end

      def get_attachment_basepath(_socket, field, entry)
          when is_atom(field) and is_map(entry) do
        "/ce_files"
      end

      def get_attachment_url(socket, field, entry) when is_atom(field) and is_map(entry) do
        path =
          Path.join(
            get_attachment_basepath(socket, field, entry),
            get_attachment_filename(socket, field, entry)
          )

        Application.get_env(:kandis, :routes).static_path(socket, path)
      end

      def get_attachment_storage_path(socket, field, entry)
          when is_atom(field) and is_map(entry) do
        Path.join(
          "priv/static",
          [
            get_attachment_basepath(socket, field, entry),
            "/",
            get_attachment_filename(socket, field, entry)
          ]
        )
      end

      def get_attachment_filename(socket, field, entry) when is_atom(field) and is_map(entry) do
        "#{socket.assigns.uid}-#{field}.#{attachment_ext(entry)}"
      end

      # example implementations:

      # def handle_event("validate" = event, msg, socket) do
      #   socket =
      #     get_upload_fields(socket)
      #     |> Enum.reduce(socket, &remove_other_uploads/2)
      #
      #   super_handle_event(event, msg, socket)
      # end

      # def handle_event("remove_attachment", %{"field" => field}, socket)
      #     when is_binary(field) do
      #   field = String.to_existing_atom(field)
      #   changed_values = %{"step_data" => socket.assigns.changeset.changes |> Map.put(field, "_")}
      #   super_handle_event("validate", changed_values, socket)
      # end

      # def handle_event("cancel_upload", %{"field" => field, "ref" => ref}, socket) do
      #   field = String.to_existing_atom(field)
      #   {:noreply, Phoenix.LiveView.cancel_upload(socket, field, ref)}
      # end

      # def handle_event("save", %{"step_data" => incoming_data}, socket) do
      #   {socket, incoming_data} =
      #     get_upload_fields(socket)
      #     |> Enum.reduce({socket, incoming_data}, fn field, {socket, incoming_data} ->
      #       {socket, put_attachment_url(socket, incoming_data, field)}
      #     end)

      #   save_step_data(incoming_data, socket)
      # end

      defp put_attachment_url(socket, incoming_data, field)
           when is_atom(field) and is_map(socket) and is_map(incoming_data) do
        {completed, []} = Phoenix.LiveView.uploaded_entries(socket, field)

        urls =
          for entry <- completed do
            get_attachment_url(socket, field, entry)
          end

        Enum.at(urls, 0)
        |> case do
          file_url when is_binary(file_url) ->
            consume_attachments(socket, [file_url], field)
            incoming_data |> Map.put(to_string(field), file_url)

          nil ->
            incoming_data
        end
      end

      def attachment_ext(entry) do
        [ext | _] = MIME.extensions(entry.client_type)
        ext
      end

      def consume_attachments(socket, urls, field) when is_atom(field) and is_list(urls) do
        Phoenix.LiveView.consume_uploaded_entries(socket, field, fn meta, entry ->
          dest = get_attachment_storage_path(socket, field, entry)

          File.cp!(meta.path, dest)
        end)

        {:ok}
      end

      # end attachment handling

      defoverridable MavuSnippetsUi.Live.Ce.CeEditBase
    end
  end

  # default clauses at and of code:
  defmacro __before_compile__(_) do
    quote do
      @impl Phoenix.LiveComponent
      def handle_event(event, msg, socket) do
        super_handle_event(event, msg, socket)
      end

      @impl Phoenix.LiveComponent
      def update(assigns, socket) do
        super_update(assigns, socket)
      end

      def save_step_data(incoming_data, context),
        do: super_save_step_data(incoming_data, context)
    end
  end
end
