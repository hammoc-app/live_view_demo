defmodule LiveViewDemoWeb.PageView do
  use LiveViewDemoWeb, :view

  def checked(_option, nil), do: ""

  def checked(option, options) do
    if option in options do
      " checked=\"checked\""
    else
      ""
    end
  end
end
