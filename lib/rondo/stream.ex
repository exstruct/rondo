defmodule Rondo.Stream do
  defstruct [:component_type, :component_path, :state_path, :id]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def create_stream() do
    %__MODULE__{}
  end
end
