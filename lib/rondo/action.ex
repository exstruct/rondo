defmodule Rondo.Action do
  defstruct [:reference, :handler, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 2, action: 3]
    end
  end

  def action(handler, reference, props \\ %{})
  def action(handler, reference = %Rondo.Store.Reference{}, props) do
    %__MODULE__{reference: reference, handler: handler, props: props}
  end
  def action(handler, _, props) do
    %__MODULE__{handler: handler, props: props}
  end
end
