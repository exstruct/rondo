defmodule Rondo.Action do
  defstruct [events: [],
             reference: nil,
             handler: nil,
             props: %{}]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 2, action: 3]
    end
  end

  def action(reference, handler, props \\ %{})
  def action(reference = %Rondo.Store.Reference{}, handler, props) do
    %__MODULE__{reference: reference, handler: handler, props: props}
  end
  def action(nil, handler, props) do
    %__MODULE__{handler: handler, props: props}
  end
end
