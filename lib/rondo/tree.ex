defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children, :actions]

  alias Rondo.Path
  alias Rondo.Component.Pointer

  def init(nil, descriptor, component_path, state, store) do
    tree = %__MODULE__{children: %{}, actions: MapSet.new()}
    init(tree, descriptor, component_path, state, store)
  end
  def init(tree = %{descriptor: descriptor, actions: actions}, descriptor, _, state, store) do
    store = Enum.reduce(actions, store, fn(action, store) ->
      {_, store} = put_action(action, store, state)
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
      (%Rondo.Store.Reference{} = ref, _path, acc) ->
        ref = resolve_state_reference(ref, state)
        {ref, acc}
      (%Rondo.Action{reference: nil}, _path, acc) ->
        {nil, acc}
      (%Rondo.Action{reference: reference} = action, _path, {children, actions, store}) ->
        {instance, store} = put_action(action, store, state)
        actions = MapSet.put(actions, action)
        {instance, {children, actions, store}}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp put_action(action = %{reference: reference}, store, state) do
    case resolve_state_reference(reference, state) do
      nil ->
        {nil, store}
      descriptor ->
        Rondo.Action.Store.put(store, %{action | reference: descriptor})
    end
  end

  defp resolve_state_reference(%{state_path: state_path}, %{children: descriptors}) do
    case Map.fetch(descriptors, state_path) do
      {:ok, %Rondo.Store{} = store} ->
        store
      _ ->
        ## TODO warn that there's a reference to an immutable/undefined path?
        nil
    end
  end
end
