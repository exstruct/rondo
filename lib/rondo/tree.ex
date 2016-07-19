defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children, :actions]

  alias Rondo.Path
  alias Rondo.Component.Pointer
  alias Rondo.Store.Reference

  def init(nil, descriptor, component_path, state, store) do
    tree = %__MODULE__{children: %{}, actions: MapSet.new()}
    init(tree, descriptor, component_path, state, store)
  end
  def init(tree = %{descriptor: descriptor, actions: actions}, descriptor, component_path, state, store) do
    store = Enum.reduce(actions, store, fn(action, store) ->
      {_, store} = put_action(action, component_path, store, state)
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
      (%Reference{} = ref, _path, acc) ->
        case Reference.resolve(ref, state.children) do
          {:ok, ref} ->
            {ref, acc}
          :error ->
            raise Reference.Error, reference: ref, component_path: component_path
        end
      (%Rondo.Action{reference: nil}, _path, acc) ->
        {nil, acc}
      (%Rondo.Action{} = action, _path, {children, actions, store}) ->
        {instance, store} = put_action(action, component_path, store, state)
        actions = MapSet.put(actions, action)
        {instance, {children, actions, store}}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp put_action(action = %{reference: %Reference{} = reference}, component_path, store, state) do
    case Reference.resolve(reference, state.children) do
      :error ->
        raise Reference.Error, reference: reference, component_path: component_path
      {:ok, nil} ->
        {nil, store}
      {:ok, descriptor} ->
        %{action | reference: descriptor}
        |> put_action(component_path, store, state)
    end
  end
  defp put_action(action, _, store, _state) do
    Rondo.Action.Store.put(store, action)
  end
end
