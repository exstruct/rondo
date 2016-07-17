defmodule Rondo.Application do
  @init __MODULE__.INIT
  @render __MODULE__.RENDER

  defstruct [phase: @init,
             manager: nil,
             components: %{},
             entry: nil]

  def init(entry, manager) do
    %__MODULE__{entry: entry, manager: manager}
  end

  def render(prev = %{entry: entry}) do
    context = %{}
    current = %{prev | components: %{}, phase: @render}
    Rondo.Path.create_root()
    |> Rondo.Component.mount(entry, context, current, prev)
  end

  def action(app = %{phase: @render}, _action) do
    app
  end

  def fetch_component(%{components: components}, path) do
    Map.fetch(components, path)
  end

  def put_component(app = %{components: components}, path, component) do
    if Map.has_key?(components, path) do
      throw :cannot_update_mounted_component
    end
    %{app | components: Map.put(components, path, component)}
  end

  def get_state(app = %{manager: manager}, component_path, state_path, descriptor) do
    {store, manager} = Rondo.Manager.create(manager, component_path, state_path, descriptor)
    {store, %{app | manager: manager}}
  end

  def update_manager(app, fun) when is_function(fun) do
    update_manager(app, fun.(app.manager))
  end
  def update_manager(app, manager) do
    %{app | manager: manager}
  end
end

defimpl Rondo.Diff, for: Rondo.Application do
  @render Rondo.Application.RENDER

  alias Rondo.Operation

  def diff(app = %{phase: @render, components: c}, %{components: c}, _path) do
    {[], app}
  end
  def diff(app = %{phase: @render, components: current}, %{components: prev}, _path) do
    {ops, prev} = Enum.reduce(current, {[], prev}, fn({path, component}, {ops, prev}) ->
      case Map.fetch(prev, path) do
        {:ok, ^component} ->
          {ops, Map.delete(prev, path)}
        {:ok, prev_component} ->
          {component_ops, _} = Rondo.Diff.diff(component, prev_component, {path, []})
          {component_ops ++ ops, Map.delete(prev, path)}
        :error ->
          %{tree: %{root: node}} = component
          {[Operation.replace(path, [], node) | ops], prev}
      end
    end)

    prev
    |> Enum.reduce({ops, app}, fn({path, component}, {ops, app}) ->
      # TODO unmount the component
      {[Rondo.Operation.remove(path, []) | ops], app}
    end)
  end
end
