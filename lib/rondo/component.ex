defmodule Rondo.Component do
  defmacro __using__(_) do
    quote do
      import Rondo.Action, only: [action: 2]
      import Rondo.Auth, only: [auth: 1, auth: 2]
      use Rondo.Element
      import Rondo.Store
    end
  end

  defstruct [:element, :context, :state, :rendering, :children, :child_context]

  alias Rondo.Element

  defmodule Placeholder do
    defstruct [:path]
  end

  def mount(path, element, context, acc, cache) do
    case Map.fetch(cache, path) do
      {:ok, component = %{element: ^element, state: state}} ->
        case Element.init(element, context) do
          ^state ->
            %{component | element: element, context: context}
            |> record(path, acc, cache)
          state ->
            %{component | element: element, context: context, state: state}
            |> render(path, acc, cache)
        end
      {:ok, component} ->
        state = Element.init(element, context)
        %{component | element: element, context: context, state: state}
        |> render(path, acc, cache)
      :error ->
        state = Element.init(element, context)
        %__MODULE__{element: element, context: context, state: state}
        |> render(path, acc, cache)
    end
  end

  defp render(component = %{element: element, rendering: rendering, children: children, state: state}, path, acc, cache) do
    component = %{component | child_context: Element.context(element, state)}
    case Element.render(element, state) do
      ^rendering ->
        component
      rendering ->
        case traverse(rendering, [0 | path]) do
          {rendering, ^children} ->
            %{component | rendering: rendering}
          {rendering, children} ->
            %{component | rendering: rendering, children: children}
        end
    end
    |> record(path, acc, cache)
  end

  defp traverse(rendering, path) do
    Rondo.Traverser.postwalk(rendering, path, %{}, fn
      (el = %Rondo.Element{type: type}, path, acc) when is_atom(type) ->
        acc = Map.put(acc, path, el) # TODO make sure we don't have conflicting keys
        {%Placeholder{path: path}, acc}
      (el, _, acc) ->
        {el, acc}
    end)
  end

  defp record(component = %{context: context, child_context: child_context, children: children}, path, acc, cache) do
    acc = Map.put(acc, path, component)
    child_context = Map.merge(context, child_context)
    Enum.reduce(children, acc, fn({path, child}, acc) ->
      mount(path, child, child_context, acc, cache)
    end)
  end
end
