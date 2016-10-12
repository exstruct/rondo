defimpl Rondo.Patchable, for: Map do
  def patch(prev, doc) do
    Enum.reduce(doc, prev, fn
      ({key, []}, acc) ->
        Map.delete(acc, key)
      ({key, [value]}, acc) ->
        Map.put(acc, key, value)
      ({to, [1, from]}, acc) ->
        {:ok, value} = Map.fetch(prev, from)
        Map.put(acc, to, value)
      ({key, op}, acc) ->
        {:ok, value} = Map.fetch(acc, key)
        value = Rondo.Patch.apply_doc(value, op)
        Map.put(acc, key, value)
    end)
  end
end
