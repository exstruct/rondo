defmodule Rondo.Element do
  defstruct [:key, :type, :props, :children]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [el: 1, el: 2, el: 3]
    end
  end

  def el(type, props \\ %{}, children \\ []) when is_map(props) or is_nil(props) do
    props = props || %{}
    %__MODULE__{key: Map.get(props, :key, nil), type: type, props: props, children: children}
  end

  def state(element = %{props: props, children: children}, context) do
    props = Map.put(props, :children, children)
    call(element, :state, [props, context], props)
  end

  def context(element, state) do
    call(element, :context, [state], %{})
  end

  def render(element, state) do
    call(element, :render, [state], nil)
  end

  defp call(%{type: type}, fun, args, default) when is_atom(type) do
    case function_exported?(type, fun, length(args)) do
      true ->
        apply(type, fun, args)
      false ->
        default
    end
  end
  defp call(_, _, _, default) do
    default
  end
end

defimpl Rondo.Diffable, for: Rondo.Element do
  def diff(current, current, _path) do
    []
  end
  def diff(curr = %{type: t, props: p}, prev = %{type: t, props: p}, path) do
    diff_children(curr, prev, path)
  end
  def diff(curr = %{type: t, props: curr_p}, prev = %{type: t, props: prev_p}, path) do
    p_ops = Rondo.Diff.diff(curr_p, prev_p, ["props" | path])
    c_ops = diff_children(curr, prev, path)
    Stream.concat(p_ops, c_ops)
  end
  def diff(curr, _, path) do
    [Rondo.Operation.replace(path, curr)]
  end

  defp diff_children(%{children: current}, %{children: current}, _path) do
    []
  end
  defp diff_children(%{children: current}, %{children: prev}, path) do
    current = children_to_map(current)
    prev = children_to_map(prev)
    Rondo.Diff.diff(current, prev, ["children" | path])
  end

  defp children_to_map(children) do
    children
    |> Enum.reduce({%{}, 0}, fn
      #TODO how do we represent ordering with a map?
      #(el = %Rondo.Element{key: key}, {map, idx}) when not is_nil(key) ->
      #  {Map.put(map, key, el), idx}
      (other, {map, idx}) ->
        {Map.put(map, idx, other), idx + 1}
    end)
    |> elem(0)
  end
end

defimpl Rondo.Traverser, for: Rondo.Element do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node, path} = replace_path(node, path)

    {node = %{props: props, children: children}, acc} = prewalk.(node, path, acc)
    {props, acc} = Rondo.Traverser.traverse(props, path, acc, prewalk, postwalk)
    {children, acc} = Rondo.Traverser.traverse(children, path, acc, prewalk, postwalk)
    postwalk.(%{node | props: props, children: children}, path, acc)
  end

  defp replace_path(node = %{key: key}, [_ | path]) when not is_nil(key) do
    {node, [key | path]}
  end
  defp replace_path(node, [key | _] = path) do
    {%{node | key: key}, path}
  end
  defp replace_path(node, []) do
    {node, []}
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
