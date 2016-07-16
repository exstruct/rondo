defmodule Rondo.Element do
  defstruct [:type, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [el: 1, el: 2, el: 3]
    end
  end

  def el(type, props \\ %{}, children \\ []) when is_map(props) or is_nil(props) do
    %__MODULE__{type: type, props: Map.put(props || %{}, :children, children)}
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

  defp call(%{type: type, props: props}, fun, state, default) when is_atom(type) do
    case function_exported?(type, fun, 2) do
      true ->
        apply(type, fun, [props, state])
      false ->
        default
    end
  end
  defp call(_, _, _, default) do
    default
  end
end

defimpl Rondo.Traverser, for: Rondo.Element do
  def traverse(node, path, acc, prewalk, postwalk) do
    # TODO replace the last path component if we have a key in the props
    {node = %{props: props = %{children: children}}, acc} = prewalk.(node, path, acc)
    {children, acc} = Rondo.Traverser.traverse(children, path, acc, prewalk, postwalk)
    postwalk.(%{node | props: %{props | children: children}}, path, acc)
  end
end
