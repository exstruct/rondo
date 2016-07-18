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
    {partial, children} = traverse(descriptor)
    %{prev | descriptor: descriptor, partial: partial, children: children, root: partial}
    |> resolve(component_path, store)
  end

  defp resolve(%{cache: cache, children: children} = state, component_path, store) do
    case lookup(children, component_path, store) do
      {^cache, store} ->
        {state, store}
      {cache, store} ->
        insert(state, cache, store)
    end
  end

  defp lookup(nil, _, store) do
    {nil, store}
  end
  defp lookup(children, component_path, store) do
    Enum.reduce(children, {%{}, store}, fn({path, descriptor}, {cache, store}) ->
      {state, store} = Rondo.State.Store.mount(store, component_path, path, descriptor)
      cache = Map.put(cache, path, state)
      {cache, store}
    end)
  end

  defp traverse(nil) do
    {nil, %{}}
  end
  defp traverse(descriptor) do
    Rondo.Traverser.postwalk(descriptor, [], %{}, fn
      (%Rondo.Store{} = store, path, acc) ->
        acc = Map.put(acc, path, store)
        {%Pointer{path: path}, acc}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp insert(%{partial: partial} = state, cache, store) do
    {root, _} = Rondo.Traverser.postwalk(partial, [], nil, fn
      (%Pointer{path: path}, _, acc) ->
        value = Map.get(cache, path)
        {value, acc}
      (node, _, acc) ->
        {node, acc}
    end)
    {%{state | root: root, cache: cache}, store}
  end
end
