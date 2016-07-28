defmodule Rondo.Event do
  defstruct [:reference, :handler, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  alias Rondo.Store.Reference

  def event(ref, handler) do
    event(ref, handler, %{})
  end
  def event(%Reference{} = ref, handler, props) do
    %__MODULE__{reference: ref, handler: handler, props: props}
  end
  def event(%Rondo.Store{} = store, handler, props) do
    %__MODULE__{reference: store, handler: handler, props: props}
  end
  def event(nil, handler, props) do
    %__MODULE__{handler: handler, props: props}
  end
end
