defmodule Rondo.Component do
  defmacro __using__(_) do
    quote do
      use Rondo.Action
      use Rondo.Element
      use Rondo.Store
    end
  end

  defstruct [:element,
             :state,
             :tree,
             :context]

  alias Rondo.State
  alias Rondo.Tree

  def mount(component = %{element: element, state: state}, path, context, state_store, action_store) do
    state_descriptor = get_state(element, context)
    case State.init(state, state_descriptor, path, state_store) do
      {^state, state_store} ->
        {component, state_store, action_store}
      {state, state_store} ->
        {context, action_store} = init_context(component, path, action_store, state)
        {tree, action_store} = init_tree(component, path, action_store, state)
        component = %{component | state: state, context: context, tree: tree}
        {component, state_store, action_store}
    end
  end

  def init_context(%{element: element, context: context}, path, action_store, state) do
    context_descriptor = get_context(element, state.root)
    Tree.init(context, context_descriptor, path, state, action_store)
  end

  defp init_tree(%{element: element, tree: tree}, path, action_store, state) do
    tree_descriptor = get_tree(element, state.root)
    Tree.init(tree, tree_descriptor, path, state, action_store)
  end

  defp get_state(element = %{props: props, children: children}, context) do
    props = Map.put(props, :children, children)
    call(element, :state, [props, context], props)
  end

  defp get_context(element, state) do
    call(element, :context, [state], %{})
  end

  defp get_tree(element, state) do
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

defimpl Rondo.Diffable, for: Rondo.Component do
  def diff(%{element: %{type: type}, tree: %{root: current}},
           %{element: %{type: type}, tree: %{root: prev}}, path) do
    Rondo.Diff.diff(current, prev, path)
  end
  def diff(%{tree: %{root: current}}, _, path) do
    [Rondo.Operation.replace(path, current)]
  end
end

defimpl Inspect, for: Rondo.Component do
  import Inspect.Algebra

  def inspect(%{element: %{type: type, props: props}, tree: %{root: tree}, state: %{root: state}, context: %{root: context}}, opts) do
    {_, state} = Map.split(state, [:children | Map.keys(props)])
    concat([
      "#Rondo.Component<",
      break(""),
      format_prop(
        "type=",
        type,
        opts
      ),
      format_prop(
        "props=",
        props,
        opts
      ),
      format_prop(
        "state=",
        state,
        opts
      ),
      format_prop(
        "context=",
        context,
        opts
      ),
      ">",
      format_tree(tree, opts)
    ])
    |> line("#Rondo.Component</>")
  end
  def inspect(%{element: element}, opts) do
    concat([
      "#Rondo.Component<PENDING>",
      format_tree(element, opts)
    ])
    |> line("#Rondo.Component</>")
  end

  defp format_tree(tree, opts) do
    nest(line(empty(), to_doc(tree, opts)), 2)
  end

  defp format_prop(name, value, opts)
  defp format_prop(_, nil, _) do
    empty
  end
  defp format_prop(_, map, _) when map_size(map) == 0 do
    empty
  end
  defp format_prop(name, value, opts) do
    concat([
      name,
      to_doc(value, opts),
      break
    ])
  end
end
