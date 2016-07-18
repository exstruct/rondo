defmodule Rondo.Component do
  defmacro __using__(_) do
    quote do
      use Rondo.Action
      import Rondo.Auth, only: [auth: 1, auth: 2]
      use Rondo.Element
      use Rondo.Store
    end
  end

  defstruct [:element,
             :state,
             :tree,
             :child_context]

  alias Rondo.Application
  alias Rondo.Element
  alias Rondo.State
  alias Rondo.Tree

  def mount(path, element, context, current, prev) do
    component = create_component(path, element, prev)
    {component, current} = init_state(path, component, context, current)
    current = Application.__put_component__(current, path, component)

    %{tree: %{children: children}, child_context: child_context} = component
    child_context = Map.merge(context, child_context)

    Enum.reduce(children, current, fn({child_path, child_element}, current) ->
      mount(child_path, child_element, child_context, current, prev)
    end)
  end

  def unmount(_component, current) do
    # TODO
    current
  end

  defp create_component(path, element, prev) do
    case Application.__fetch_component__(prev, path) do
      {:ok, component = %{element: ^element}} ->
        component
      _ ->
        %__MODULE__{element: element}
    end
  end

  defp init_state(path, component = %{element: element, state: state}, context, current) do
    state_descriptor = Element.state(element, context)
    case State.init(state, state_descriptor, path, current) do
      {^state, current} ->
        {component, current}
      {state, current} ->
        %{component | state: state}
        |> render(path, current)
    end
  end

  defp render(component = %{element: element, state: %{root: state}, tree: tree}, path, current) do
    child_context = Element.context(element, state)
    tree_descriptor = Element.render(element, state)
    case Tree.init(tree, tree_descriptor, path, current) do
      {^tree, current} ->
        {%{component | child_context: child_context}, current}
      {tree, current} ->
        {%{component | child_context: child_context, tree: tree}, current}
    end
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
