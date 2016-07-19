defmodule Rondo.Test do
  def render(element, state_store, context \\ %{})
  def render(element = %Rondo.Element{}, state_store, context) do
    element
    |> Rondo.create_application()
    |> render(state_store, context)
  end
  def render(app, state_store, context) do
    Rondo.Application.render(app, state_store, context)
  end

  def render_shallow(element, state_store, context \\ %{})
  def render_shallow(element = %Rondo.Element{}, state_store, context) do
    element
    |> Rondo.create_application()
    |> render_shallow(state_store, context)
  end
  def render_shallow(app = %{action_store: action_store}, state_store, context) do
    path = Rondo.Path.create_root()
    action_store = action_store |> Rondo.Action.Store.init()

    {component, state_store, action_store} =
      %Rondo.Component{element: app.entry}
      |> Rondo.Component.mount(path, context, state_store, action_store)

    action_store = Rondo.Action.Store.finalize(action_store)

    app = %{app | phase: Rondo.Application.RENDER,
                  components: %{path => component},
                  action_store: action_store}

    {app, state_store}
  end

  def fetch_path(%Rondo.Application{components: components}, path) do
    components
    |> resolve()
    |> fetch_path(path)
  end
  def fetch_path(value, []) do
    {:ok, value}
  end
  def fetch_path(%Rondo.Element{children: children}, [item | _] = path) when is_integer(item) do
    fetch_path(children, path)
  end
  def fetch_path(map, [item | path]) when is_map(map) do
    case Map.fetch(map, item) do
      {:ok, value} ->
        fetch_path(value, path)
      :error ->
        :error
    end
  end
  def fetch_path([value | _], [0 | path]) do
    fetch_path(value, path)
  end
  def fetch_path([_ | list], [key | path]) when is_integer(key) do
    fetch_path(list, [key - 1 | path])
  end
  def fetch_path(_, _) do
    :error
  end

  def find_element(%Rondo.Application{components: components}, fun) do
    components
    |> resolve()
    |> find_element(fun)
  end
  def find_element(tree, fun) do
    tree
    |> Rondo.Traverser.postwalk([], [], fn
      (%Rondo.Element{} = node, _, acc) ->
        case fun.(node) do
          true ->
            {node, [node | acc]}
          _ ->
            {node, acc}
        end
      (node, _, acc) ->
        {node, acc}
    end)
    |> elem(1)
    |> :lists.reverse()
  end

  def submit_action(app, store, ref, data) do
    case Rondo.Application.prepare_action(app, ref, data) do
      {:invalid, errors, app} ->
        {:invalid, errors, app, store}
      {:ok, descriptors, app} ->
        case apply_descriptors(descriptors, store) do
          {:ok, store} ->
            {app, store} = Rondo.Application.render(app, store)
            {:ok, app, store}
          {:error, error, store} ->
            {:error, error, app, store}
        end
    end
  end

  defp apply_descriptors([], store) do
    {:ok, store}
  end
  defp apply_descriptors([{descriptor, update_fn} | descriptors], store) do
    case Rondo.State.Store.handle_action(store, descriptor, update_fn) do
      {:ok, store} ->
        apply_descriptors(descriptors, store)
      {:error, error, store} ->
        {:error, error, store}
    end
  end

  defp resolve(components, path \\ Rondo.Path.create_root()) do
    components
    |> get_component(path)
    |> Rondo.Traverser.prewalk([], nil, fn
      (%Rondo.Component.Pointer{path: path}, _, acc) ->
        component = resolve(components, path)
        {component, acc}
      (node, _, acc) ->
        {node, acc}
    end)
    |> elem(0)
  end

  defp get_component(components, path) do
    components
    |> Map.get(path)
    |> tree()
  end

  defp tree(%{tree: %{root: root}}) do
    root
  end
end