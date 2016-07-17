defmodule Rondo.Operation do
  defmodule Remove do
    defstruct [:path]
  end

  defmodule Replace do
    defstruct [:path, :value]
  end

  def remove(path) do
    %Remove{path: :lists.reverse(path)}
  end

  def replace(path, value) do
    %Replace{path: :lists.reverse(path), value: value}
  end

  # def move
  # def copy - worth it?
end
