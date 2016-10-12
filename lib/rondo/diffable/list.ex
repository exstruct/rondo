defimpl Rondo.Diffable, for: List do
  def diff(curr, prev, path) do
    curr = with_index(curr, 0, %{})
    prev = with_index(prev, 0, %{})
    Rondo.Diffable.Map.diff(curr, prev, path)
  end

  defp with_index([], _, acc) do
    acc
  end
  defp with_index([item | list], i, acc) do
    acc = Map.put(acc, i, item)
    with_index(list, i + 1, acc)
  end
end
