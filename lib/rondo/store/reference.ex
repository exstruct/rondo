defmodule Rondo.Store.Reference do
  defstruct [:state_path]

  def mut(state_path) do
    %__MODULE__{state_path: state_path}
  end
end
