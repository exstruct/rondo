defmodule Rondo.Tree do
  defstruct [:descriptor, :root, :children]

  defmodule Placeholder do
    defstruct [:path]
  end

  alias Rondo.Path

  def init(nil, descriptor, component_path) do
    init(%__MODULE__{children: %{}}, descriptor, component_path)
  end
  def init(tree = %{descriptor: descriptor}, descriptor, _) do
    tree
  end
  def init(tree, descriptor, component_path) do
    {root, children} = traverse(descriptor, component_path)
    %{tree |
       descriptor: descriptor,
       root: root,
       children: children}
  end

  def traverse(descriptor, component_path) do
    Rondo.Traverser.postwalk(descriptor, [], %{}, fn
      (%Rondo.Element{type: type} = el, path, acc) when is_atom(type) ->
        path = Path.create_child_path(component_path, path)
        acc = Map.put(acc, path, el)
        {%Placeholder{path: path}, acc}
      (node, _, acc) ->
        {node, acc}
    end)
  end
end

defimpl Rondo.Diff, for: Rondo.Tree.Placeholder do
  def diff(%{path: path} = current, %{path: path}, _path) do
    {[], current}
  end
  def diff(current, _prev, {component, path}) do
    {[Rondo.Operation.replace(component, path, current)], current}
  end
end

defimpl Inspect, for: Rondo.Tree.Placeholder do
  import Inspect.Algebra

  def inspect(%{path: path}, opts) do
    concat([
      "#Rondo.Tree.Placeholder<",
      "path=",
      to_doc(path, opts),
      ">"
    ])
  end
end
