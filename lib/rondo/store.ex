defmodule Rondo.Store do
  defstruct [:component_path, :state_path, :props, :id, :type]

  defmacro __using__(_) do
    quote do
      import Rondo.Store
      use Rondo.Store.Reference
    end
  end

  def create_store() do
    create_store(%{}, :ephemeral, nil)
  end
  def create_store(props) do
    create_store(props, :ephemeral, nil)
  end
  def create_store(props, type) do
    create_store(props, type, nil)
  end
  def create_store(props, type, id) do
    %__MODULE__{props: props, id: id, type: type}
  end
end
