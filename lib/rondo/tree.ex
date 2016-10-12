defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children, :actions]

  alias Rondo.Path
  alias Rondo.Component.Pointer
  alias Rondo.Store.Reference

  def init(nil, descriptor, component_path, state, store) do
    tree = %__MODULE__{children: %{}, actions: MapSet.new()}
    init(tree, descriptor, component_path, state, store)
  end
  def init(tree = %{descriptor: descriptor, actions: actions}, descriptor, _component_path, _state, store) do
    store = Enum.reduce(actions, store, fn(action, store) ->
      {_, store} = Rondo.Action.Store.put(store, action)
      store
    end)
    {tree, store}
  end
  def init(tree, descriptor, component_path, state, store) do
    {root, {children, actions, store}} = traverse(descriptor, component_path, state, store)
    tree = %{tree | descriptor: descriptor, root: root, children: children, actions: actions}
    {tree, store}
  end

  def add_actions(%{actions: actions}, store) do
    Enum.reduce(actions, store, fn(action, store) ->
      {_, store} = Rondo.Action.Store.put(store, action)
      store
    end)
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
      (%Rondo.Action{} = action, _path, {children, actions, store} = acc) ->
        case resolve_action(action, component_path, state) do
          nil ->
            {nil, acc}
          action ->
            actions = MapSet.put(actions, action)
            {instance, store} = Rondo.Action.Store.put(store, action)
            {instance, {children, actions, store}}
        end
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp resolve_action(action = %{reference: reference, events: events}, component_path, %{children: children}) do
    case resolve(reference, children, component_path) do
      nil ->
        nil
      descriptor ->
        events = resolve_events(events, component_path, children, [])
        %{action | reference: descriptor, events: events}
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
