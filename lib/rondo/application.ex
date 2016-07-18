defmodule Rondo.Application do
  @init __MODULE__.INIT
  @render __MODULE__.RENDER

  defstruct [phase: @init,
             manager: nil,
             components: %{},
             entry: nil,
             actions: %Rondo.Action.Manager{}]

  def init(entry) do
    %__MODULE__{entry: entry}
  end

  def render(prev = %{entry: entry, actions: actions}, manager, context \\ %{}) do
    actions = Rondo.Action.Manager.init(actions)
    current = %{prev | components: %{}, actions: actions, phase: @render, manager: manager}
    path = Rondo.Path.create_root()
    app = Rondo.Component.mount(path, entry, context, current, prev)

    {%{app | actions: Rondo.Action.Manager.finalize(app.actions), manager: nil}, app.manager}
  end

  def diff(%{components: curr_components, actions: curr_affordances, phase: @render},
           %{components: prev_components, actions: prev_affordances}) do
    curr = %{"components" => curr_components, "affordances" => curr_affordances}
    prev = %{"components" => prev_components, "affordances" => prev_affordances}
    Rondo.Diff.diff(curr, prev)
  end

  def prepare_action(app = %{components: components, actions: actions, phase: @render}, action_ref, data) do
    case Rondo.Action.Manager.prepare_update(actions, action_ref, data) do
      {:invalid, errors, actions} ->
        {:invalid, errors, %{app | actions: actions}}
      {:ok, component_path, state_path, update_fn, actions} ->
        ## TODO lookup state descriptor for state_path in component
        descriptor = nil
        {:ok, component_path, state_path, descriptor, update_fn, %{app | actions: actions}}
    end
  end

  def __fetch_component__(%{components: components}, path) do
    Map.fetch(components, path)
  end

  def __put_component__(app = %{components: components}, path, component) do
    if Map.has_key?(components, path) do
      throw :cannot_update_mounted_component
    end
    %{app | components: Map.put(components, path, component)}
  end

  def __mount_state__(app = %{manager: manager}, component_path, state_path, descriptor) do
    {store, manager} = Rondo.Manager.mount(manager, component_path, state_path, descriptor)
    {store, %{app | manager: manager}}
  end

  def __put_action__(app = %{actions: actions}, component_path, descriptor) do
    {affordance, actions} = Rondo.Action.Manager.put(actions, component_path, descriptor)
    {affordance, %{app | actions: actions}}
  end
end
