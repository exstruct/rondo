defimpl Rondo.Patchable, for: List do
  def patch(prev, doc) do
    prev = prev
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn({value, idx}, acc) ->
      Map.put(acc, idx, value)
    end)

    prev
    |> Rondo.Patchable.Map.patch(doc)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end
end
