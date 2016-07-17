defprotocol Rondo.Diff do
  def diff(current, prev, path \\ [])
end

defimpl Rondo.Diff, for: Map do
  ## TODO make this more efficient with remove and copy?
  def diff(curr, prev, {component_path, path}) do
    {ops, prev} = Enum.reduce(curr, {[], prev}, fn({key, value}, {ops, prev}) ->
      case Map.fetch(prev, key) do
        {:ok, ^value} ->
          {ops, Map.delete(prev, key)}
        {:ok, prev_value} ->
          {v_ops, _} = Rondo.Diff.diff(value, prev_value, {component_path, [key | path]})
          {v_ops ++ ops, Map.delete(prev, key)}
        :error ->
          {[Rondo.Operation.replace(component_path, [key | path], value) | ops], prev}
      end
    end)

    prev
    |> Enum.reduce({ops, curr}, fn({key, value}, {ops, curr}) ->
      {[Rondo.Operation.remove(component_path, [key | path]) | ops], curr}
    end)
  end
end

defimpl Rondo.Diff, for: [Atom, BitString, Integer, Float] do
  def diff(current, current, _) do
    {[], current}
  end
  def diff(current, _, {c_path, path}) do
    {[Rondo.Operation.replace(c_path, path, current)], current}
  end
end
