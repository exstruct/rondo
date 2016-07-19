defmodule Rondo.Store do
  defstruct [:component_path, :state_path, :props, :id, :type]

  defmacro __using__(_) do
    quote do
      import Rondo.Store
      import Rondo.Store.Reference
    end
  end

  def create_store() do
    create_store(%{}, nil, :ephemeral)
  end
  def create_store(props) do
    create_store(props, nil, :ephemeral)
  end
  def create_store(props, id) do
    create_store(props, id, :persistent)
  end
  def create_store(props, id, type) do
    %__MODULE__{props: props, id: id, type: type}
  end
end
