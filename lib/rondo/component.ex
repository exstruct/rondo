defmodule Rondo.Component do
  defmacro __using__(_) do
    quote do
      import Rondo.Action, only: [action: 2]
      import Rondo.Auth, only: [auth: 1, auth: 2]
      use Rondo.Element
      import Rondo.Store, only: [create_store: 0, create_store: 1, create_store: 2, create_store: 3]
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
    current = Application.put_component(current, path, component)

    %{tree: %{children: children}, child_context: child_context} = component
    child_context = Map.merge(context, child_context)

    Enum.reduce(children, current, fn({child_path, child_element}, current) ->
      mount(child_path, child_element, child_context, current, prev)
    end)
  end

  def diff(_current, _prev) do
    # TODO
    []
  end

  def unmount(_component, current) do
    # TODO
    current
  end

  defp create_component(path, element, prev) do
    case Application.fetch_component(prev, path) do
      {:ok, component = %{element: ^element}} ->
        component
      _ ->
        %__MODULE__{element: element}
    end
  end

  defp init_state(path, component = %{element: element, state: state}, context, current) do
    state_descriptor = Element.init(element, context)
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
    case Tree.init(tree, tree_descriptor, path) do
      ^tree ->
        {%{component | child_context: child_context}, current}
      tree ->
        {%{component | child_context: child_context, tree: tree}, current}
    end
  end
end

defimpl Rondo.Diff, for: Rondo.Component do
  ## TODO if it's a totally different type just replace it
  def diff(%{tree: %{root: current}}, %{tree: %{root: prev}}, path) do
    {ops, _} = Rondo.Diff.diff(current, prev, path)
    {ops, current}
  end
end

defimpl Inspect, for: Rondo.Component do
  import Inspect.Algebra

  def inspect(%{element: %{type: type, props: props}, tree: %{root: tree}, state: %{root: state}}, opts) do
    concat([
      "#Rondo.Component<",
      break(""),
      "type=",
      to_doc(type, opts),
      break,
      "props=",
      to_doc(props, opts),
      break,
      "state=",
      to_doc(state, opts),
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
end
