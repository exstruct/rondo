defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children, :actions]

  alias Rondo.Path
  alias Rondo.Component.Pointer

  def init(nil, descriptor, component_path, state, store) do
    tree = %__MODULE__{children: %{}, actions: MapSet.new()}
    init(tree, descriptor, component_path, state, store)
  end
  def init(tree = %{descriptor: descriptor, actions: actions}, descriptor, component_path, state, store) do
    store = Enum.reduce(actions, store, fn(action, store) ->
      {_, store} = Rondo.Action.Store.put(store, component_path, action, state)
      store
    end)
    {tree, store}
  end
  def init(tree, descriptor, component_path, state, store) do
    {root, {children, actions, store}} = traverse(descriptor, component_path, state, store)
    tree = %{tree | descriptor: descriptor, root: root, children: children, actions: actions}
    {tree, store}
  end

  def traverse(descriptor, component_path, state, store) do
    acc = {%{}, MapSet.new(), store}
    Rondo.Traverser.postwalk(descriptor, [], acc, fn
      (%Rondo.Element{type: type} = el, path, {children, actions, store}) when is_atom(type) ->
        path = Path.create_child_path(component_path, path)
        children = Map.put(children, path, el)
        {%Pointer{path: path}, {children, actions, store}}
      (%Rondo.Action{} = action, _path, {children, actions, store}) ->
        {instance, store} = Rondo.Action.Store.put(store, component_path, action, state)
        actions = MapSet.put(actions, action)
        {instance, {children, actions, store}}
      (node, _, acc) ->
        {node, acc}
    end)
  end
end
