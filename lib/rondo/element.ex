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

  def init(element, context) do
    call(element, :init, context, nil)
  end

  def context(element, state) do
    call(element, :context, state, %{})
  end

  def render(element, state) do
    call(element, :render, state, nil)
  end

  defp call(%{type: type, props: props, children: children}, fun, state, default) when is_atom(type) do
    case function_exported?(type, fun, 2) do
      true ->
        apply(type, fun, [Map.put(props, :children, children), state])
      false ->
        default
    end
  end
  defp call(_, _, _, default) do
    default
  end
end

defimpl Rondo.Diff, for: Rondo.Element do
  def diff(current, current, _path) do
    {[], current}
  end
  def diff(curr = %{type: t, props: p}, prev = %{type: t, props: p}, path) do
    ops = diff_children(curr, prev, path)
    {ops, curr}
  end
  def diff(curr = %{type: t, props: curr_p}, prev = %{type: t, props: prev_p}, path = {c_path, i_path}) do
    c_ops = diff_children(curr, prev, path)
    {p_ops, _} = Rondo.Diff.diff(curr_p, prev_p, {c_path, [:"$props" | i_path]})
    {p_ops ++ c_ops, curr}
  end
  def diff(curr, _, {c_path, path}) do
    {[Rondo.Operation.replace(c_path, path, curr)], curr}
  end

  defp diff_children(%{children: current}, %{children: current}, _path) do
    []
  end
  defp diff_children(%{children: current}, %{children: prev}, path) do
    current = children_to_map(current)
    prev = children_to_map(prev)
    {ops, _} = Rondo.Diff.diff(current, prev, path)
    ops
  end

  defp children_to_map(children) do
    children
    |> Enum.reduce({%{}, 0}, fn
      (el = %Rondo.Element{key: key}, {map, idx}) ->
        {Map.put(map, key, el), idx + 1}
      (other, {map, idx}) ->
        {Map.put(map, idx, other), idx + 1}
    end)
    |> elem(0)
  end
end

defimpl Rondo.Traverser, for: Rondo.Element do
  def traverse(node, path, acc, prewalk, postwalk) do
    {node, path} = replace_path(node, path)
    {node = %{children: children}, acc} = prewalk.(node, path, acc)
    {children, acc} = Rondo.Traverser.traverse(children, path, acc, prewalk, postwalk)
    postwalk.(%{node | children: children}, path, acc)
  end

  defp replace_path(node = %{key: key}, [_ | path]) do
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
