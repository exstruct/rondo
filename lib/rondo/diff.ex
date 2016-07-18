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
