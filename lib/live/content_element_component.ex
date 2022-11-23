defmodule MavuSnippetsUi.Live.ContentElementComponent do
  use MavuSnippetsUiWeb, :live_component

  def human_ctype(txt) do
    txt |> String.replace("ce_", "")
  end

  def component_name_for_ctype(ctype) when is_binary(ctype) do
    String.to_atom("Elixir.MavuSnippetsUi.Live.Ce." <> Macro.camelize(ctype))
  end

  def module_exists?(module) do
    function_exported?(module, :render, 1)
  end
end
