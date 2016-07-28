defmodule Test.Rondo.Component.State do
  use Test.Rondo.Case

  context :from_props do
    defmodule Component do
      use Rondo.Component

      def state(props, _context) do
        %{
          name: props[:name] || "Joe"
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

    "state with props" ->
      {app, _store} = el(Component, %{name: "Robert"}) |> render()

      assert_path app, [0], "Robert"
  end

  context :from_context do
    defmodule Component do
      use Rondo.Component

      def state(_props, context) do
        %{
          name: context[:name] || "Mike"
        }
      end

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end
  after
    "state" ->
      {app, _store} = render(Component)

      assert_path app, [0], "Mike"

    "with context" ->
      {app, _store} = render(Component, %TestStore{}, %{name: "Joe"})

      assert_path app, [0], "Joe"
  end

  context :create_store do
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

    "modified state" ->
      {app, store} = render(Component)

      store = TestStore.update_all(store, fn({descriptor, _value}) ->
        {descriptor, "Robert"}
      end)

      {app, _store} = render(app, store)

      assert_path app, [0], "Robert"
  end

  context :passed_reference do
    defmodule First do
      use Rondo.Component

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end

    defmodule Second do
      use Rondo.Component

      def state(_props, _context) do
        %{
          user: create_store(%{name: "Joe"})
        }
      end

      def render(_state) do
        el(First, ref([:user]))
      end
    end
  after
    "ref" ->
      {app, _store} = render(Second)

      assert_path app, [0], "Joe"

    "updated_ref" ->
      {app, store} = render(Second)

      store = TestStore.update_all(store, fn({descriptor, _value}) ->
        {descriptor, %{name: "Robert"}}
      end)

      {app, _store} = render(app, store)

      assert_path app, [0], "Robert"
  end
end
