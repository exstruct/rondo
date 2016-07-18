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
             :child_context]

  alias Rondo.State
  alias Rondo.Tree

  def mount(component, path, context, state_store, action_store) do
    init_state(component, path, context, state_store, action_store)
  end

  defp init_state(component = %{element: element, state: state}, path, context, state_store, action_store) do
    state_descriptor = state(element, context)
    case State.init(state, state_descriptor, path, state_store) do
      {^state, state_store} ->
        {component, state_store, action_store}
      {state, state_store} ->
        %{component | state: state}
        |> render(path, state_store, action_store)
    end
  end

  defp render(component = %{element: element, state: state, tree: tree}, path, state_store, action_store) do
    child_context = context(element, state.root)
    tree_descriptor = render(element, state.root)
    case Tree.init(tree, tree_descriptor, path, state, action_store) do
      {^tree, action_store} ->
        component = %{component | child_context: child_context}
        {component, state_store, action_store}
      {tree, action_store} ->
        component = %{component | child_context: child_context, tree: tree}
        {component, state_store, action_store}
    end
  end

  defp state(element = %{props: props, children: children}, context) do
    props = Map.put(props, :children, children)
    call(element, :state, [props, context], props)
  end

  defp context(element, state) do
    call(element, :context, [state], %{})
  end

  defp render(element, state) do
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

  def inspect(%{element: %{type: type, props: props}, tree: %{root: tree}, state: %{root: state}, child_context: context}, opts) do
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
