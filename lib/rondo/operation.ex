defmodule Rondo.Operation do
  defstruct [:op, :component, :path, :value]

  def remove(component, path) do
    %__MODULE__{component: component, path: path, op: :REMOVE}
  end

  def replace(component, path, node) do
    %__MODULE__{component: component, path: path, value: node, op: :REPLACE}
  end

  # def move
  # def copy - worth it?
end
