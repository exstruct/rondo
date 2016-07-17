defmodule Rondo do
  alias Rondo.Application

  def create_application(element, store) do
    Application.init(element, store)
  end

  def render(app) do
    Application.render(app)
  end

  def diff(current, prev) do
    {diff, current} = Rondo.Diff.diff(current, prev)
    {:lists.reverse(diff), current}
  end
end
