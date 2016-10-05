defmodule Rondo.Operation do
  defmodule Remove do
    defstruct [:path]
  end

  defmodule Replace do
    defstruct [:path, :value]
  end

  defmodule Copy do
    defstruct [:from, :to]
  end

  def remove(path) do
    %Remove{path: :lists.reverse(path)}
  end

  def replace(path, value) do
    %Replace{path: :lists.reverse(path), value: value}
  end

  def copy(from, to) do
    %Copy{from: :lists.reverse(from), to: :lists.reverse(to)}
  end
end
