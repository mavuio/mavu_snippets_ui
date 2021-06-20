defmodule MavuSnippetsUi.Live.ContentListComponent do
  use MavuSnippetsUiWeb, :live_component

  import MavuUtils

  def update(assigns, socket) do
    {:ok,
     socket
     |> Phoenix.LiveView.assign(assigns)
     |> Phoenix.LiveView.assign(css_id: String.replace("#{assigns.id}", ~r/[^a-z0-9_-]/, "_"))
     |> Phoenix.LiveView.assign(
       moving_element_uid: nil,
       clipboard_size: (assigns.context.clipboard.(:get, nil) || []) |> length()
     )}
  end

  def handle_event("delete_ce", %{"uid" => uid} = msg, socket) do
    msg |> log("delete_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:delete_ce, %{uid: uid, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("copy_ce", %{"uid" => uid} = msg, socket) do
    msg |> log("copy_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:copy_ce, %{uid: uid, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("copy_multiple_ce", uids, socket) do
    uids |> log("copy_multiple_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:copy_multiple_ce, %{uids: uids, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("cut_multiple_ce", uids, socket) do
    uids |> log("cut_multiple_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:cut_multiple_ce, %{uids: uids, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("delete_multiple_ce", uids, socket) do
    uids |> log("delete_multiple_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:delete_multiple_ce, %{uids: uids, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("paste_ce", msg, socket) do
    msg |> log("paste_ce, send for path #{socket.assigns.path}", :info)

    send(
      self(),
      {:pass_down,
       {:paste_ce, %{path: socket.assigns.path, uid: msg["uid"], position: msg["position"]}}}
    )

    {:noreply, socket}
  end

  def handle_event("add_ce", msg, socket) do
    msg |> log("add_ce, send for path #{socket.assigns.path}", :info)

    {:noreply,
     socket
     |> push_patch(
       to:
         socket.assigns.base_path.(%{
           "rec" => socket.assigns.rec_id,
           "uid" => msg["uid"],
           "position" => msg["position"],
           "action" => "add"
         })
     )}
  end

  def handle_event("duplicate_ce", %{"uid" => uid} = msg, socket) do
    msg |> log("duplicate_ce, send for path #{socket.assigns.path}", :info)
    send(self(), {:pass_down, {:duplicate_ce, %{uid: uid, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("move_ce", %{"uid" => uid, "direction" => direction} = msg, socket) do
    msg |> log("move_ce,#{direction} send for path #{socket.assigns.path}", :info)

    send(
      self(),
      {:pass_down, {:move_ce, %{uid: uid, direction: direction, path: socket.assigns.path}}}
    )

    {:noreply, socket}
  end

  def handle_event("show_move_ui", %{"uid" => uid} = msg, socket) do
    msg |> log("show_move_ui", :info)
    send(self(), {:pass_down, {:show_move_ui, %{uid: uid, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("hide_move_ui", msg, socket) do
    msg |> log("hide_move_ui", :info)
    send(self(), {:pass_down, {:hide_move_ui, msg}})

    {:noreply, socket}
  end

  def handle_event("show_menu", %{"uid" => uid} = msg, socket) do
    msg |> log("show_menu", :info)
    send(self(), {:pass_down, {:show_menu, %{uid: uid, path: socket.assigns.path}}})

    {:noreply, socket}
  end

  def handle_event("hide_menu", msg, socket) do
    msg |> log("hide_menu", :info)
    send(self(), {:pass_down, {:hide_menu, msg}})

    {:noreply, socket}
  end

  def handle_event("show_multiselect_ui", msg, socket) do
    msg |> log("show_multiselect_ui", :info)
    send(self(), {:pass_down, {:show_multiselect_ui, %{path: socket.assigns.path}}})
    {:noreply, socket}
  end

  def handle_event("hide_multiselect_ui", msg, socket) do
    msg |> log("hide_multiselect_ui", :info)
    send(self(), {:pass_down, {:hide_multiselect_ui, msg}})

    {:noreply, socket}
  end
end
