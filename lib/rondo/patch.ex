defmodule Rondo.Patch do
  alias Rondo.Operation

  defstruct [:doc, :empty?]

  def to_patch(diff) when is_list(diff) do
    doc = diff
    |> :lists.flatten()
    |> Enum.reduce(%{}, &to_doc/2)

    %__MODULE__{
      doc: doc,
      empty?: is_map(doc) && map_size(doc) == 0
    }
  end

  def apply(%{doc: doc}, prev \\ nil) do
    apply_doc(prev, doc)
  end

  defp to_doc(%Operation.Copy{from: from, to: to}, acc) do
    put(acc, to, [1, List.last(from)])
  end
  defp to_doc(%Operation.Remove{path: path}, acc) do
    put(acc, path, [])
  end
  defp to_doc(%Operation.Replace{path: path, value: value}, acc) do
    put(acc, path, [value])
  end

  defp put(_, [], value) do
    value
  end
  defp put(acc, path, value) when is_list(acc) do
    [0, acc, put(%{}, path, value)]
  end
  defp put(acc, [key | path], value) do
    child =
      case Map.fetch(acc, key) do
        {:ok, child} ->
          put(child, path, value)
        :error ->
          put(%{}, path, value)
      end
    Map.put(acc, key, child)
  end

  def apply_doc(_, []) do
    nil
  end
  def apply_doc(_, [value]) do
    value
  end
  def apply_doc(value, [0 | ops]) do
    Enum.reduce(ops, value, fn(op, value) ->
      apply_doc(value, op)
    end)
  end
  def apply_doc(_, [1, _]) do
    throw :invalid_copy
  end
  def apply_doc(prev, doc) do
    Rondo.Patchable.patch(prev, doc)
  end
end
