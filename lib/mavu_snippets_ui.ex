defmodule MavuSnippetsUi do
  @moduledoc false

  def default_conf(local_conf \\ %{}) do
    %{
      snippet_groups_module: MavuSnippets.SnippetGroups,
      snippet_group_module: MavuSnippets.SnippetGroup,
      repo: MyApp.Repo
    }
    |> Map.merge(local_conf)
  end

  def get_conf_val(conf, key) when is_atom(key) do
    conf =
      if MavuUtils.empty?(conf) do
        default_conf()
      else
        conf
      end

    conf[key]
  end

  def handle_info_from_top_liveview({:push_patch, opts}, socket) do
    # handle push_patch in top-level liveview, becaus we cannot do it in component's update() method
    {:noreply, socket |> Phoenix.LiveView.push_patch(opts)}
  end

  def handle_info_from_top_liveview(payload, socket) do
    # put message into liveview-assigns, to pass it down to our components
    {:noreply, Phoenix.LiveView.assign(socket, mavu_snippets_ui_msg: payload)}
  end
end
