defmodule MavuSnippetsUi.Live.EditSnippetGroupComponent do
  @moduledoc false
  use MavuSnippetsUiWeb, :live_component

  alias MavuContent.Clist

  import MavuUtils

  def snippet_groups_module(assigns),
    do: assigns[:context][:snippets_ui_conf][:snippet_groups_module]

  # def update(%{msg: :ignore}, socket) do
  #   "ignore" |> IO.inspect(label: "mwuits-debug 2021-06-20_22:19 ❖ ")
  #   {:ok, socket}
  # end

  @impl true
  def update(%{mavu_snippets_ui_msg: msg}, socket) when not is_nil(msg) do
    msg |> IO.inspect(label: "mwuits-debug 2021-06-20_22:19 ❖ ")
    msg |> IO.inspect(label: "mwuits-debug 2021-06-20_13:23 received pass-down msg")
    res = handle_root_msg(msg, socket)
    send(self(), {:mavu_snippets_ui_msg, nil})
    res
  end

  def update(assigns, socket) do
    # add properties to context:

    assigns =
      update_in(assigns.context, fn context ->
        context
        |> Map.merge(%{
          moving_element: socket.assigns[:context][:moving_element],
          menuing_element: socket.assigns[:context][:menuing_element],
          multiselect_path: socket.assigns[:context][:multiselect_path],
          clipboard: get_clipboard(socket),
          active_langs: get_active_langs_from_params(context[:params], context[:snippets_conf])
        })
      end)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        snippet_group:
          snippet_groups_module(assigns).get_snippet_group(
            MavuUtils.to_int(assigns.rec_id),
            assigns[:context][:snippets_ui_conf]
          )
      )

    socket =
      socket
      |> assign(contentlist: socket.assigns.snippet_group.content)

    {:ok, socket}
  end

  def get_active_langs_from_params(%{"langs" => langs_str} = _params, snippets_conf) do
    available_langs = MavuSnippets.available_langs(snippets_conf)

    langs_str
    |> String.split("-")
    |> Enum.filter(fn lang -> Enum.member?(available_langs, lang) end)
    |> case do
      [] -> get_active_langs_from_params(nil, snippets_conf)
      list -> list
    end
  end

  def get_active_langs_from_params(_params, snippets_conf) do
    [MavuSnippets.default_lang(snippets_conf)]
  end

  def lang_is_active(lang, context) when is_binary(lang) and is_map(context) do
    Map.get(context, :active_langs, [])
    |> Enum.member?(lang)
  end

  def get_clipboard(_socket) do
    username = "manfred123"
    MavuSnippetsUi.ClipboardStorage.create("snippet_group_edit:clipboard:#{username}")
  end

  def close_menu(%{assigns: %{context: %{menuing_element: element}}} = socket)
      when not is_nil(element) do
    socket |> assign(:context, put_in(socket.assigns.context, [:menuing_element], nil))
  end

  def close_menu(socket), do: socket

  def close_multiselect(%{assigns: %{context: %{multiselect_path: element}}} = socket)
      when not is_nil(element) do
    socket |> assign(:context, put_in(socket.assigns.context, [:multiselect_path], nil))
  end

  def close_multiselect(socket), do: socket

  @impl true
  def handle_event("toggle_language_in_params", %{"lang" => toggled_lang}, socket) do
    new_langs =
      if Enum.member?(socket.assigns.context.active_langs, toggled_lang) do
        socket.assigns.context.active_langs |> List.delete(toggled_lang)
      else
        MavuSnippets.available_langs(socket.assigns.context[:snippets_conf])
        |> Enum.filter(fn lang ->
          Enum.member?(socket.assigns.context.active_langs, lang) or lang == toggled_lang
        end)
      end

    new_params = Map.put(socket.assigns.context[:params], "langs", Enum.join(new_langs, "-"))

    {:noreply, socket |> push_patch(to: socket.assigns.base_path.(new_params))}
  end

  def handle_root_msg({:copy_multiple_ce, %{uids: uids, path: path} = msg}, socket) do
    msg |> log("info copy_ce received #{__MODULE__}", :info)
    clipboard = get_clipboard(socket)
    Clist.copy(socket.assigns.contentlist, path, uids, clipboard)

    clipboard_content = clipboard.(:get, nil) || []

    {:ok,
     socket
     #  |> close_multiselect()
     |> put_flash(:info, "#{clipboard_content |> length()} elements copied to the clipboard")}
  end

  def handle_root_msg({:cut_multiple_ce, %{uids: uids, path: path} = msg}, socket) do
    msg |> log("info cut_ce received #{__MODULE__}", :info)
    Clist.cut(socket.assigns.contentlist, path, uids, get_clipboard(socket))

    {:ok,
     socket
     #  |> close_multiselect()
     |> put_flash(:info, "#{length(uids)} elements cutted to the clipboard")}
  end

  def handle_root_msg({:delete_multiple_ce, %{uids: uids, path: path} = msg}, socket) do
    msg |> log("info delete_ce received #{__MODULE__}", :info)

    contentlist = Clist.remove(socket.assigns.contentlist, path, uids)

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.socket.assigns[:context][:snippets_ui_conf]
    )

    {:ok,
     socket
     #  |> close_multiselect()
     |> assign(:contentlist, contentlist)
     |> put_flash(:info, "#{length(uids)} elements deleted")}
  end

  def handle_root_msg({:copy_ce, %{uid: uid, path: path} = msg}, socket) do
    msg |> log("info copy_ce received #{__MODULE__}", :info)
    Clist.copy(socket.assigns.contentlist, path, [uid], get_clipboard(socket))

    {:ok,
     socket
     |> close_menu()
     |> put_flash(:info, "1 element copied to the clipboard")}
  end

  def handle_root_msg({:paste_ce, %{path: path} = msg}, socket) do
    msg |> log("info paste_ce received #{__MODULE__}", :info)

    contentlist =
      Clist.paste(
        socket.assigns.contentlist,
        path,
        msg[:uid],
        msg[:position],
        get_clipboard(socket)
      )

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    {:ok,
     socket
     |> close_menu()
     |> assign(:contentlist, contentlist)}
  end

  def handle_root_msg({:add_ce, %{path: path, items: items} = msg}, socket) do
    msg |> log("info add_ce received #{__MODULE__}", :info)

    contentlist =
      Clist.add(
        socket.assigns.contentlist,
        path,
        msg[:uid],
        msg[:position],
        items
      )

    new_uid =
      case items do
        [item | _] -> item["uid"]
        _ -> nil
      end

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    {:ok,
     socket
     |> close_menu()
     |> assign(:contentlist, contentlist)
     |> push_patch(
       #  to: Routes.sheet_modify_path(socket, :edit, socket.assigns.snippet_group, path, new_uid)
       to:
         socket.assigns.base_path.(%{
           action: :edit,
           rec_id: socket.assigns.snippet_group.id,
           path: path,
           uid: new_uid
         })
     )}
  end

  def handle_root_msg({:delete_ce, %{uid: uid, path: path} = msg}, socket) do
    msg |> log("info delete_ce received #{__MODULE__}", :info)
    contentlist = Clist.remove(socket.assigns.contentlist, path, uid)

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    {:ok,
     socket
     |> assign(:contentlist, contentlist)}
  end

  def handle_root_msg({:duplicate_ce, %{uid: uid, path: path} = msg}, socket) do
    msg |> log("info duplicate_ce received #{__MODULE__}", :info)
    contentlist = Clist.duplicate(socket.assigns.contentlist, path, uid)

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    {:ok,
     socket
     |> assign(:contentlist, contentlist)}
  end

  def handle_root_msg({:move_ce, %{uid: uid, direction: direction, path: path} = msg}, socket) do
    socket.assigns.context[:moving_element]
    |> IO.inspect(label: "mwuits-debug 2021-06-20_13:10 MOVINGA")

    msg |> log("info move_ce #{direction} received #{__MODULE__}", :info)
    contentlist = Clist.move(socket.assigns.contentlist, path, uid, direction)

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    {
      :ok,
      socket
      |> assign(:contentlist, contentlist)
      #  |> close_menu()
    }
  end

  def handle_root_msg({:show_move_ui, %{uid: uid, path: path} = msg}, socket) do
    msg |> log("info show_move_ui #{uid} #{path} received #{__MODULE__}", :info)

    case socket.assigns.context.moving_element do
      {^path, ^uid} ->
        # close if already open
        handle_root_msg({:hide_move_ui, msg}, socket)

      _ ->
        {:ok,
         socket
         |> assign(
           :context,
           put_in(socket.assigns.context, [:moving_element], {path, uid})
         )}
    end
  end

  def handle_root_msg({:hide_move_ui, msg}, socket) do
    msg |> log("info hide_move_ui received #{__MODULE__}", :info)

    {:ok,
     socket
     |> assign(:context, put_in(socket.assigns.context, [:moving_element], nil))}
  end

  def handle_root_msg({:show_menu, %{uid: uid, path: path} = msg}, socket) do
    msg |> log("info show_move_ui #{uid} #{path} received #{__MODULE__}", :info)

    case socket.assigns.context.menuing_element do
      {^path, ^uid} ->
        # close if already open
        handle_root_msg({:hide_menu, msg}, socket)

      _ ->
        {:ok,
         socket
         |> assign(
           :context,
           put_in(socket.assigns.context, [:menuing_element], {path, uid})
         )}
    end
  end

  def handle_root_msg({:hide_menu, msg}, socket) do
    msg |> log("info hide_menu received #{__MODULE__}", :info)

    {:ok,
     socket
     |> assign(:context, put_in(socket.assigns.context, [:menuing_element], nil))}
  end

  def handle_root_msg({:show_multiselect_ui, %{path: path} = msg}, socket) do
    msg |> log("info show_multiselect_ui #{path} received #{__MODULE__}", :info)

    socket =
      socket
      |> close_menu()

    case socket.assigns.context.multiselect_path do
      ^path ->
        # close if already open
        handle_root_msg({:hide_multiselect_ui, msg}, socket)

      _ ->
        {:ok,
         socket
         |> assign(
           :context,
           put_in(socket.assigns.context, [:multiselect_path], path)
         )}
    end
  end

  def handle_root_msg({:hide_multiselect_ui, msg}, socket) do
    msg |> log("info hide_multiselect_ui received #{__MODULE__}", :info)

    {:ok,
     socket
     |> assign(:context, put_in(socket.assigns.context, [:multiselect_path], nil))}
  end

  def handle_root_msg(
        {:update_ce, %{uid: uid, path: path, data: data} = msg, next_action},
        socket
      ) do
    {msg, next_action}
    |> log("info update_ce #{path}.#{uid} received #{__MODULE__}", :info)

    contentlist = Clist.replace(socket.assigns.contentlist, path, uid, data)

    snippet_groups_module(socket.assigns).update_snippet_group(
      socket.assigns.snippet_group,
      %{
        content: contentlist
      },
      socket.assigns[:context][:snippets_ui_conf]
    )

    socket =
      case next_action do
        :close ->
          # next_url = Routes.sheet_modify_path(socket, :modify, socket.assigns.snippet_group)

          next_url =
            socket.assigns.base_path.(%{action: :modify, rec: socket.assigns.snippet_group.id})

          send(self(), {:mavu_snippets_ui_msg, {:push_patch, [to: next_url]}})

          socket

        _ ->
          socket
      end

    # |> put_flash(:info, "content-element updated successfully")

    {:ok,
     socket
     |> assign(:contentlist, contentlist)}
  end
end
