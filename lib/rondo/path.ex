defmodule Rondo.Path do
  defstruct [path: [], parent: nil]

  def create_root() do
    %__MODULE__{path: []}
  end

  def create_child_path(parent, path) do
    %__MODULE__{path: :lists.reverse(path), parent: parent}
  end

  def to_list(path), do: to_list(path, [])
  defp to_list(%{parent: nil, path: path}, acc) do
    [path | acc]
  end
  defp to_list(%{parent: parent, path: path}, acc) do
    to_list(parent, [path | acc])
  end

  def from_list(path) do
    path
    |> from_list(nil)
  end
  defp from_list([], path) do
    path
  end
  defp from_list([path | paths], parent) do
    from_list(paths, %__MODULE__{parent: parent, path: path})
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
    |> to_doc(opts)
  end
end
