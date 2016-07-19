defmodule Rondo.Action do
  defstruct [events: [],
             reference: nil,
             handler: nil,
             props: %{}]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 2, action: 3, action: 4]
    end
  end

  def action(reference, handler, props \\ %{}, events \\ [])
  def action(reference = %Rondo.Store.Reference{}, handler, props, events) do
    %__MODULE__{reference: reference, handler: handler, props: props, events: events}
  end
  def action(nil, handler, props, events) do
    %__MODULE__{handler: handler, props: props, events: events}
  end
end
