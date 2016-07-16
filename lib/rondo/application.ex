defmodule Rondo.Application do
  @needs_render __MODULE__.NEEDS_RENDER

  defstruct [instances: %{}, entry: nil]

  def init(entry) do
    %__MODULE__{entry: entry}
  end

  def render(app = %{instances: @needs_render}) do
    render(%{app | instances: %{}})
  end
  def render(app = %{entry: entry, instances: instances}) do
    instances = Rondo.Component.mount([], entry, %{}, %{}, instances)
    %{app | instances: instances}
  end

  def action(app, _action) do
    app
  end

  def diff(%{instance: @needs_render}, _) do
    throw :NEEDS_RENDER
  end
  def diff(current, _prev) do
    current
  end
end
