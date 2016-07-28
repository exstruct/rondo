defmodule Test.Rondo.Test.Store do
  use Test.Rondo.Case
  alias Rondo.State.Store

  test "round trip" do
    store = TestStore.init(%{})

    store = Store.handle_info(store, :INFO)

    bin = Store.encode(store)

    assert store == Store.decode_into(store, bin)
  end
end
