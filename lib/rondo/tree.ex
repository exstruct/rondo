defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children, :actions]

  defmodule Placeholder do
    defstruct [:path]
  end

  alias Rondo.Path

  def init(nil, descriptor, component_path, app) do
    init(%__MODULE__{children: %{}, actions: MapSet.new()}, descriptor, component_path, app)
  end
  def init(tree = %{descriptor: descriptor, actions: actions}, descriptor, component_path, app) do
    app = Enum.reduce(actions, app, fn(action, app) ->
      {_, app} = Rondo.Application.__put_action__(app, component_path, action)
      app
    end)
    {tree, app}
  end
  def init(tree, descriptor, component_path, app) do
    {root, {children, actions, app}} = traverse(descriptor, component_path, app)
    {%{tree |
       descriptor: descriptor,
       root: root,
       children: children,
       actions: actions}, app}
  end

  def traverse(descriptor, component_path, app) do
    Rondo.Traverser.postwalk(descriptor, [], {%{}, MapSet.new(), app}, fn
      (%Rondo.Element{type: type} = el, path, {children, actions, app}) when is_atom(type) ->
        path = Path.create_child_path(component_path, path)
        children = Map.put(children, path, el)
        {%Placeholder{path: path}, {children, actions, app}}
      (%Rondo.Action{} = action, _path, {children, actions, app}) ->
        {instance, app} = Rondo.Application.__put_action__(app, component_path, action)
        actions = MapSet.put(actions, action)
        {instance, {children, actions, app}}
      (node, _, acc) ->
        {node, acc}
    end)
  end
end

defimpl Rondo.Diff, for: Rondo.Tree.Placeholder do
  def diff(%{path: path}, %{path: path}, _path) do
    []
  end
  def diff(current, _prev, path) do
    [Rondo.Operation.replace(path, current)]
  end
end

defimpl Inspect, for: Rondo.Tree.Placeholder do
  import Inspect.Algebra

  def inspect(%{path: path}, opts) do
    concat([
      "#Rondo.Tree.Placeholder<",
      "path=",
      to_doc(path, opts),
      ">"
    ])
  end
end
