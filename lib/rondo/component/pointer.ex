defmodule Rondo.Component.Pointer do
  defstruct [:type, :props, :children, :path]
end

defimpl Rondo.Diffable, for: Rondo.Component.Pointer do
  def diff(%{path: path}, %{path: path}, _path) do
    []
  end
  def diff(current, _prev, path) do
    [Rondo.Operation.replace(path, current)]
  end
end

defimpl Inspect, for: Rondo.Component.Pointer do
  import Inspect.Algebra

  def inspect(%{path: path}, opts) do
    concat([
      "#Rondo.Component.Pointer<",
      "path=",
      to_doc(path, opts),
      ">"
    ])
  end
end
