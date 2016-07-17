defmodule Rondo.Action do
  defstruct [:action, :path, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [action: 1, action: 2, action: 3]
    end
  end

  def action(action, path \\ [], props \\ %{}) do
    %__MODULE__{action: action, path: path, props: props}
  end

  def init(%{action: action}) do

  end
end
