defmodule Rondo.Event do
  defstruct [:reference, :handler, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  alias Rondo.Store.Reference
  alias Rondo.Action

  def event(ref, handler) do
    event(ref, handler, %{})
  end
  def event(%Reference{} = ref, handler, props) when is_atom(handler) do
    %__MODULE__{reference: ref, handler: handler, props: props}
  end
  def event(%Action{} = action, ref, handler) do
    event(action, ref, handler, %{})
  end
  def event(%Action{events: events} = action, ref, handler, props) do
    %{action | events: events ++ [event(ref, handler, props)]}
  end
end
