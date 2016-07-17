defmodule Rondo.State do
  defstruct [:descriptor, :partial, :children, :cache, :root]

  alias Rondo.Application

  defmodule Placeholder do
    defstruct [:path]
  end

  def init(nil, descriptor, component_path, app) do
    init(%__MODULE__{cache: %{}}, descriptor, component_path, app)
  end
  def init(%{descriptor: descriptor} = state, descriptor, component_path, app) do
    resolve(state, component_path, app)
  end
  def init(prev, descriptor, component_path, app) do
    {partial, children} = traverse(descriptor)
    %{prev | descriptor: descriptor, partial: partial, children: children, root: partial}
    |> resolve(component_path, app)
  end

  defp resolve(%{cache: cache, children: children} = state, component_path, app) do
    case lookup(children, component_path, app) do
      {^cache, app} ->
        {state, app}
      {cache, app} ->
        insert(state, cache, app)
    end
  end

  defp lookup(nil, _, app) do
    {nil, app}
  end
  defp lookup(children, component_path, app) do
    Enum.reduce(children, {%{}, app}, fn({path, descriptor}, {cache, app}) ->
      {state, app} = Application.__mount_state__(app, component_path, path, descriptor)
      {Map.put(cache, path, state), app}
    end)
  end

  defp traverse(nil) do
    {nil, %{}}
  end
  defp traverse(descriptor) do
    Rondo.Traverser.postwalk(descriptor, [], %{}, fn
      (%Rondo.Store{} = store, path, acc) ->
        acc = Map.put(acc, path, store)
        {%Placeholder{path: path}, acc}
      (node, _, acc) ->
        {node, acc}
    end)
  end

  defp insert(%{partial: partial} = state, cache, app) do
    {root, _} = Rondo.Traverser.postwalk(partial, [], nil, fn
      (%Placeholder{path: path}, _, acc) ->
        value = Map.get(cache, path)
        {value, acc}
      (node, _, acc) ->
        {node, acc}
    end)
    {%{state | root: root, cache: cache}, app}
  end
end
