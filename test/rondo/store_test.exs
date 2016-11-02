defmodule Test.Rondo.Store do
  use Test.Rondo.Case
  alias Rondo.Store

  context :ephemeral do
    defmodule Component do
      use Rondo.Component

      def state(_props, _context) do
        %{
          name: create_store("Joe")
        }
      end

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end
  after
    "state" ->
      {app, _store} = render(Component)

      assert_path app, [0], "Joe"
  end

  context :ephemeral_function do
    defmodule Component do
      use Rondo.Component

      def state(_props, _context) do
        %{
          name: create_store(fn ->
            "Robert"
          end)
        }
      end

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end
  after
    "state" ->
      {app, _store} = render(Component)

      assert_path app, [0], "Robert"
  end

  context :instance do
    defmodule AsyncStore do
      use Rondo.Store.Handler

      def create(key, %{time: time, value: value}) do
        ref = :erlang.send_after(time, self(), {key, value})
        {{ref, key}, :PENDING}
      end

      def update({ref, key}, props) do
        :timer.cancel(ref)
        create(key, props)
      end

      def handle_message(state, message) do
        {state, message}
      end

      def handle_update(state, new_value) do
        {state, new_value}
      end

      def stop({ref, _key}) do
        :timer.cancel(ref)
        :ok
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(_props, context) do
        %{
          name: create_store(%{time: 10, value: context[:value] || :foo}, AsyncStore)
        }
      end

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end
  after
    "async" ->
      {app, store} = render(Component)

      assert_path app, [0], :PENDING # make sure it's loading

      store = await store

      {app, _store} = render(app, store)

      assert_path app, [0], :foo

    "async cancel" ->
      {app, store} = render(Component)

      assert_path app, [0], :PENDING

      await store # throw away the other value - we're going to update it

      context = %{value: :bar}
      {app, store} = render(app, store, context)
      # TODO fix this!
      # assert_path app, [0], :PENDING

      store = await store
      {app, _store} = render(app, store, context)
      assert_path app, [0], :bar
  end

  defp await(store) do
    receive do
      msg ->
        Store.handle_info(store, msg)
    after
      1000 ->
        throw :store_timeout
    end
  end
end
