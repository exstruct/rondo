defmodule Rondo.Action do
  defstruct [:action, :path, :props]

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def action(action, path \\ [], props \\ %{}) do
    %__MODULE__{action: action, path: path, props: props}
  end
end
