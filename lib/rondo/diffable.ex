defprotocol Rondo.Diffable do
  def diff(current, prev, path)
end

defimpl Rondo.Diffable, for: Map do
  ## TODO make this more efficient with remove and copy?
  def diff(curr, prev, path) do
    {ops, prev} = Enum.reduce(curr, {[], prev}, fn({key, value}, {ops, prev}) ->
      case Map.fetch(prev, key) do
        {:ok, ^value} ->
          {ops, Map.delete(prev, key)}
        {:ok, prev_value} ->
          case Rondo.Diff.diff(value, prev_value, [key | path]) do
            [] ->
              {ops, Map.delete(prev, key)}
            v_ops ->
              {Stream.concat(ops, v_ops), Map.delete(prev, key)}
          end
        :error ->
          op = Rondo.Operation.replace([key | path], value)
          {Stream.concat(ops, [op]), prev}
      end
    end)

    case map_size(prev) do
      0 ->
        ops
      _ ->
        remove_ops = Stream.map(prev, fn({key, _}) ->
          Rondo.Operation.remove([key | path])
        end)

        Stream.concat(ops, remove_ops)
    end
  end
end

defimpl Rondo.Diffable, for: [Atom, BitString, Integer, Float] do
  def diff(current, current, _) do
    []
  end
  def diff(current, _, path) do
    [Rondo.Operation.replace(path, current)]
  end
end
