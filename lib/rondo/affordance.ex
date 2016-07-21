defmodule Rondo.Affordance do
  defstruct [:ref, :schema_id, :schema]
end

defimpl Rondo.Diffable, for: Rondo.Affordance do
  def diff(a, b, path) do
    Rondo.Diffable.diff(Map.from_struct(a), Map.from_struct(b), path)
  end
end
