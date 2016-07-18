defmodule Rondo.Application do
  @init __MODULE__.INIT
  @render __MODULE__.RENDER

  defstruct [phase: @init,
             components: %{},
             entry: nil,
             action_store: %Rondo.Action.Store{}]

  def init(entry) do
    %__MODULE__{entry: entry}
  end

  def render(app = %{entry: entry, action_store: action_store}, state_store, context \\ %{}) do
    path = Rondo.Path.create_root()
    current = %{}
    prev = app.components
    action_store = Rondo.Action.Store.init(action_store)

    {components, state_store, action_store} =
      render_component(path, entry, context, current, prev, state_store, action_store)

    action_store = Rondo.Action.Store.finalize(action_store)
    app = %{app | components: components, action_store: action_store, phase: @render}
    {app, state_store}
  end

  defp render_component(path, element, context, current, prev, state_store, action_store) do
    component = create_component(prev, path, element)

    {component, state_store, action_store} =
      Rondo.Component.mount(component, path, context, state_store, action_store)

    current = put_component(current, path, component)

    %{tree: %{children: children}, child_context: child_context} = component
    child_context = Map.merge(context, child_context)
    acc = {current, state_store, action_store}

    children
    |> Enum.reduce(acc, fn({path, element}, {current, state, action}) ->
      render_component(path, element, child_context, current, prev, state, action)
    end)
  end

  defp create_component(components, path, element) do
    case Map.fetch(components, path) do
      {:ok, component = %{element: ^element}} ->
        component
      _ ->
        %Rondo.Component{element: element}
    end
  end

  defp put_component(components, path, component) do
    if Map.has_key?(components, path) do
      throw :cannot_update_mounted_component
    end
    Map.put(components, path, component)
  end

  def diff(%{components: curr_components, action_store: curr_affordances, phase: @render},
           %{components: prev_components, action_store: prev_affordances}) do
    curr = %{"components" => curr_components, "schemas" => curr_affordances}
    prev = %{"components" => prev_components, "schemas" => prev_affordances}
    Rondo.Diff.diff(curr, prev)
  end

  def prepare_action(app = %{action_store: actions, phase: @render}, action_ref, data) do
    case Rondo.Action.Store.prepare_update(actions, action_ref, data) do
      {:invalid, errors, action_store} ->
        app = %{app | action_store: action_store}
        {:invalid, errors, app}
      {:ok, component_path, state_path, descriptor, update_fn, action_store} ->
        app = %{app | action_store: action_store}
        {:ok, component_path, state_path, descriptor, update_fn, app}
    end
  end
end
