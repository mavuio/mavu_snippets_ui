defmodule MavuSnippetsUi.Utils.TwIconLegacy do
  require Phoenix.LiveViewTest

  @dialyzer {:nowarn_function, tw_icon_legacy: 2}

  def tw_icon_legacy(icon_fun, size) when is_integer(size) and is_function(icon_fun, 1) do
    tw_icon_legacy(icon_fun, %{class: "w-#{size} h-#{size}"})
  end

  def tw_icon_legacy(icon_fun, class)
      when is_binary(class) and is_function(icon_fun, 1) do
    tw_icon_legacy(icon_fun, %{class: class})
  end

  def tw_icon_legacy(icon_fun, opts) when is_list(opts) and is_function(icon_fun, 1) do
    tw_icon_legacy(icon_fun, opts |> Enum.into(%{}))
  end

  def tw_icon_legacy(icon_fun, opts) when is_map(opts) and is_function(icon_fun, 1) do
    # icon_html = icon_fun.(%{class: opts[:class]})

    Phoenix.LiveViewTest.render_component(icon_fun, class: opts[:class]) |> Phoenix.HTML.raw()
  end
end
