defmodule Rondo.Diff do
  def diff(current, prev, path \\ [])
  def diff(current, prev, path) do
    case {get_type(current), get_type(prev)} do
      {t, t} ->
        Rondo.Diffable.diff(current, prev, path)
      {_, _} ->
        [Rondo.Operation.replace(path, current)]
    end
  end

  def get_type(%{__struct__: s}) do
    s
  end
  for type <- [:atom, :binary, :bitstring, :float, :function, :integer, :list, :map, :tuple] do
    def get_type(t) when unquote(:"is_#{type}")(t) do
      unquote(type)
    end
  end
  def get_type(_) do
    nil
  end
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
