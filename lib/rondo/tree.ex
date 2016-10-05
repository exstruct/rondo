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
      (%Rondo.Element{type: type, props: props, children: c} = el, path, {children, actions, store}) when not is_binary(type) ->
        path = Path.create_child_path(component_path, path)
        children = Map.put(children, path, el)
        {%Pointer{type: type, props: props, children: c, path: path}, {children, actions, store}}
      (%Reference{} = ref, _path, acc) ->
        ref = resolve(ref, state.children, component_path)
        {ref, acc}
      (%Rondo.Action{reference: nil}, _path, acc) ->
        {nil, acc}
      (%Rondo.Action{} = action, _path, {children, actions, store}) ->
        {instance, store} = put_action(action, component_path, store, state)
        actions = MapSet.put(actions, action)
        {instance, {children, actions, store}}
      (%Rondo.Stream.Subscription{} = sub, _path, {children, actions, store}) ->
        {sub, {children, actions, store}}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp put_action(action = %{reference: reference, events: events}, component_path, store, %{children: children}) do
    case resolve(reference, children, component_path) do
      nil ->
        {nil, store}
      descriptor ->
        events = resolve_events(events, component_path, children, [])
        action = %{action | reference: descriptor,
                            events: events}
        Rondo.Action.Store.put(store, action)
    end
  end

  defp resolve_events([], _, _, acc) do
    :lists.reverse(acc)
  end
  defp resolve_events([event = %{reference: ref} | events], component_path, children, acc) do
    case resolve(ref, children, component_path) do
      nil ->
        resolve_events(events, component_path, children, acc)
      descriptor ->
        event = %{event | reference: descriptor}
        resolve_events(events, component_path, children, [event | acc])
    end
  end

  defp resolve(%Reference{} = reference, children, component_path) do
    case Reference.resolve(reference, children) do
      :error ->
        raise Reference.Error, reference: reference, component_path: component_path
      {:ok, nil} ->
        nil
      {:ok, descriptor} ->
        descriptor
    end
  end
  defp resolve(%Rondo.Store{} = store, _, _) do
    store
  end
end
