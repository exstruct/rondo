defmodule Rondo.Element do
  defstruct [key: nil,
             type: nil,
             props: %{},
             children: []]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [el: 1, el: 2, el: 3]
    end
  end

  def el(type, props \\ %{}, children \\ []) when is_map(props) or is_nil(props) do
    props = props || %{}
    key = Map.get(props, :key, nil)
    %__MODULE__{key: key, type: type, props: props, children: children}
  end
end

defimpl Rondo.Diffable, for: Rondo.Element do
  def diff(current, current, _path) do
    []
  end
  def diff(%{type: t, props: curr_p, children: curr_c},
           %{type: t, props: prev_p, children: prev_c}, path) do
    curr_p = Map.delete(curr_p, :key)
    prev_p = Map.delete(prev_p, :key)
    curr = %{"props" => curr_p, "children" => curr_c}
    prev = %{"props" => prev_p, "children" => prev_c}
    Rondo.Diff.diff(curr, prev, path)
  end
  def diff(curr, _, path) do
    [Rondo.Operation.replace(path, curr)]
  end
end

defimpl Rondo.Patchable, for: Rondo.Element do
  def patch(%{props: props, children: children} = el, doc) do
    %{"props" => props, "children" => children} =
      @protocol.Map.patch(%{"props" => props, "children" => children}, doc)
    %{el | props: props, children: children}
  end
end

defimpl Rondo.Traverser, for: Rondo.Element do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node = %{props: props, children: children}, acc} = prewalk.(node, path, acc)
    {props, acc} = Rondo.Traverser.traverse(props, path, acc, prewalk, postwalk)
    {children, acc} = Rondo.Traverser.traverse(children, path, acc, prewalk, postwalk)
    postwalk.(%{node | props: props, children: children}, path, acc)
  end
end

defimpl Inspect, for: Rondo.Element do
  import Inspect.Algebra

  def inspect(%{type: type, props: props, children: children}, opts) do
    concat([
      "#Rondo.Element<", concat([
        "type=", to_doc(type, opts),
        " props=",
        to_doc(Map.delete(props, :children), opts)
      ])
    ])
    |> format_children(children, opts)
  end

  defp format_children(header, [], _) do
    concat([header, " />"])
  end
  defp format_children(header, children, opts) do
    c = Enum.reduce(children, break, fn(child, parent) ->
      glue(
        parent,
        nest(line(break(), to_doc(child, opts)), 2)
      )
    end)
    concat([header, ">", line(c, "#Rondo.Element</>")])
  end
end
