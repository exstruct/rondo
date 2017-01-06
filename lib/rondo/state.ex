defmodule Rondo.State do
  defstruct [:descriptor, :partial, :children, :cache, :root]

  defmodule Pointer do
    defstruct [:path]
  end

  def init(nil, descriptor, component_path, store) do
    init(%__MODULE__{cache: %{}}, descriptor, component_path, store)
  end
  def init(%{descriptor: descriptor} = state, descriptor, component_path, store) do
    resolve(state, component_path, store)
  end
  def init(prev, descriptor, component_path, store) do
    {partial, children} = traverse(descriptor, component_path)
    %{prev | descriptor: descriptor, partial: partial, children: children, root: partial}
    |> resolve(component_path, store)
  end

  defp resolve(%{cache: cache, children: children, root: root} = state, component_path, store) do
    case lookup(children, store) do
      {^cache, store} ->
        state = %{state | root: Enum.reduce(cache, root, fn({path, value}, root) ->
          put_in(root, path, value)
        end)}
        {state, store}
      {cache, store} ->
        insert(state, component_path, cache, store)
    end
  end

  defp traverse(nil, _) do
    {nil, %{}}
  end
  defp traverse(descriptor, component_path) do
    Rondo.Traverser.postwalk(descriptor, [], %{}, fn
      (%Rondo.Store{component_path: nil} = store, path, acc) ->
        store = %{store | component_path: component_path, state_path: path}
        acc = Map.put(acc, path, store)
        {%Pointer{path: path}, acc}
      (%Rondo.Store{} = store, path, acc) ->
        acc = Map.put(acc, path, store)
        {%Pointer{path: path}, acc}
      (%Rondo.Store.Reference{} = ref, path, acc) ->
        acc = Map.put(acc, path, ref)
        {ref, acc}
      (%Rondo.Stream{component_path: nil} = stream, path, acc) ->
        id = :erlang.phash2({component_path, path})
        stream = %{stream | component_path: component_path, state_path: path, id: id}
        acc = Map.put(acc, path, stream)
        sub = %Rondo.Stream.Subscription{id: id}
        {sub, acc}
      (%Rondo.Stream{id: id} = stream, path, acc) ->
        acc = Map.put(acc, path, stream)
        sub = %Rondo.Stream.Subscription{id: id}
        {sub, acc}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp lookup(nil, store) do
    {nil, store}
  end
  defp lookup(children, store) do
    Enum.reduce(children, {%{}, store}, fn
      ({_, %Rondo.Stream{}}, acc) ->
        acc
      ({path, descriptor}, {cache, store}) ->
        {state, store} = Rondo.State.Store.mount(store, descriptor)
        cache = Map.put(cache, path, state)
        {cache, store}
    end)
  end

  defp insert(%{partial: partial} = state, component_path, cache, store) do
    {root, _} = Rondo.Traverser.postwalk(partial, [], nil, fn
      (%Rondo.Store.Reference{} = ref, _, acc) ->
        case Rondo.Store.Reference.resolve(ref, cache, :value) do
          {:ok, value} ->
            {value, acc}
          :error ->
            raise Rondo.Store.Reference.Error, reference: ref, component_path: component_path
        end
      (%Pointer{path: path}, _, acc) ->
        value = Map.get(cache, path)
        {value, acc}
      (node, _, acc) ->
        {node, acc}
    end)
    {%{state | root: root, cache: cache}, store}
  end
end
