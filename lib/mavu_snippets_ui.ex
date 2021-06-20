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
end
