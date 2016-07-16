defmodule Rondo.Store do
  defstruct [:id, :type]

  def create_store() do
    %__MODULE__{id: nil,
                type: :ephemeral}
  end
  def create_store(id) do
    %__MODULE__{id: id,
                type: :persistent}
  end

  def init(stores, storage) do
    ## TODO initialize each store from the storage
    stores
  end
end
