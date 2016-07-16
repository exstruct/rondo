defmodule Rondo.Action do
  defstruct [:action, :store]

  defmacro __using__(_) do

  end

  def action(action, store) do
    %__MODULE__{action: action, store: store}
  end
end
