defprotocol Rondo.Traverser do
  @fallback_to_any true

  def traverse(root, path, acc, prewalk, postwalk)

  Kernel.def prewalk(root, path, acc, prewalk) do
    traverse(root, path, acc, prewalk, &noop/3)
  end

  Kernel.def postwalk(root, path, acc, postwalk) do
    traverse(root, path, acc, &noop/3, postwalk)
  end

  Kernel.defp noop(node, _, acc) do
    {node, acc}
  end
end

defimpl Rondo.Traverser, for: Map do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node, acc} = prewalk.(node, path, acc)
    {node, acc} = Enum.reduce(node, {%{}, acc}, fn({key, value}, {map, acc}) ->
      {value, acc} = Rondo.Traverser.traverse(value, [key | path], acc, prewalk, postwalk)
      {Map.put(map, key, value), acc}
    end)
    postwalk.(node, path, acc)
  end
end

defimpl Rondo.Traverser, for: List do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node, acc} = prewalk.(node, path, acc)
    {_, node, acc} = Enum.reduce(node, {0, [], acc}, fn(value, {i, list, acc}) ->
      {value, acc} = Rondo.Traverser.traverse(value, [i | path], acc, prewalk, postwalk)
      {i + 1, [value | list], acc}
    end)
    postwalk.(:lists.reverse(node), path, acc)
  end
end

defimpl Rondo.Traverser, for: Any do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node, acc} = prewalk.(node, path, acc)
    postwalk.(node, path, acc)
  end
end
