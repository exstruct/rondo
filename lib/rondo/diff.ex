defmodule Rondo.Diff do
  def diff(current, prev, path \\ [])
  def diff(%{__struct__: s} = curr, %{__struct__: s} = prev, path) do
    Rondo.Diffable.diff(curr, prev, path)
  end
  for type <- [:atom, :binary, :bitstring, :float, :function, :integer, :list, :map, :tuple] do
    check = :"is_#{type}"
    def diff(current, prev, path) when unquote(check)(current) and unquote(check)(prev) do
      Rondo.Diffable.diff(current, prev, path)
    end
  end
  def diff(current, _prev, path) do
    [Rondo.Operation.replace(path, current)]
  end
end
