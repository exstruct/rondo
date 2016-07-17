defmodule Rondo.Action do
  defstruct [:state_path, :handler, :props, :events]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 2, action: 3, action: 4]
    end
  end

  def action(handler, state_path, props \\ %{}, events \\ []) when is_list(state_path) do
    %__MODULE__{state_path: state_path, handler: handler, props: props, events: events}
  end
end
