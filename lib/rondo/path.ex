defmodule Rondo.Path do
  defstruct [:path, :parent]

  def create_root() do
    %__MODULE__{path: []}
  end

  def create_child_path(parent, path) do
    %__MODULE__{path: path, parent: parent}
  end
end

defimpl Inspect, for: Rondo.Path do
  import Inspect.Algebra

  def inspect(path, opts) do
    concat(format_path(path, [">"], opts))
  end

  defp format_path(%{parent: nil, path: path}, acc, opts) do
    ["#Rondo.Path<", path_to_doc(path, opts) | acc]
  end
  defp format_path(%{parent: parent, path: path}, acc, opts) do
    format_path(parent, [path_to_doc(path, opts) | acc], opts)
  end

  defp path_to_doc(path, opts) do
    path
    |> :lists.reverse()
    |> to_doc(opts)
  end
end
