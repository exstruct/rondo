defmodule Rondo.Schema do
  defstruct [:schema]
end

defimpl Rondo.Diffable, for: Rondo.Schema do
  def diff(%{schema: current}, %{schema: prev}, path) do
    Rondo.Diffable.diff(current, prev, path)
  end
end
