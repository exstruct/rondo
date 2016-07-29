defmodule Rondo.Test.Store do
  defstruct [stores: %{}, action_error: nil]

  def init(_) do
    %__MODULE__{}
  end

  def update_all(%{stores: stores} = store, fun) do
    stores = Stream.map(stores, fun) |> Enum.into(%{})
    %{store | stores: stores}
  end

  def put_action_error(store, error) do
    %{store | action_error: error}
  end

  defimpl Rondo.State.Store do
    def mount(%{stores: stores} = store, %{props: initial} = descriptor) do
      stores = Map.put_new(stores, descriptor, initial)
      {Map.get(stores, descriptor), %{store | stores: stores}}
    end

    def handle_info(store, _info) do
      store
    end

    def handle_action(%{action_error: error} = store, _, _) when not is_nil(error) do
      {:error, error, store}
    end
    def handle_action(store, descriptor, update_fn) do
      {prev, store} = mount(store, descriptor)
      value = update_fn.(prev)
      stores = Map.put(store.stores, descriptor, value)
      {:ok, %{store| stores: stores}}
    end

    def encode(%{stores: stores}) do
      stores
      |> :erlang.term_to_binary()
      |> Base.url_encode64()
    end

    def decode_into(store, bin) do
      stores = bin
      |> Base.url_decode64!()
      |> :erlang.binary_to_term()
      %{store | stores: stores}
    end
  end
end
