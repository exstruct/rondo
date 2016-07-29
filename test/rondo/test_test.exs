defmodule Test.Rondo.Test do
  use Test.Rondo.Case

  context :render_shallow do
    defmodule First do
      use Rondo.Component

      def render(_) do
        throw :IT_RENDERED
      end
    end

    defmodule Second do
      use Rondo.Component

      def render(_) do
        el(First)
      end
    end
  after
    "call" ->
      {app, _store} = render_shallow(Second, %TestStore{})

      assert_path app, [], %{type: First}
  end

  context :find_element do
    defmodule Component do
      use Rondo.Component

      def render(_) do
        nest(100)
      end

      defp nest(0) do
        el("Item", %{key: :foo})
      end
      defp nest(count) when rem(count, 2) == 0 do
        el("Container", nil, [nest(count - 1)])
      end
      defp nest(count) do
        el("Item", %{key: :foo}, [nest(count - 1)])
      end
    end
  after
    "render" ->
      {app, _store} = render(Component)

      elements = find_element(app, fn
        (%{key: :foo}) ->
          true
        (_) ->
          false
      end)

      assert length(elements) == 51
  end

  context :action_error do
    defmodule Action do
      def affordance(_) do
        %{}
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(_, _) do
        %{
          thing: create_store()
        }
      end

      def render(_) do
        el("Item", %{action: action(ref([:thing]), Action)})
      end
    end
  after
    "put_action_error" ->
      {app, store} = render(Component)

      store = TestStore.put_action_error(store, "You goofed!")

      {:ok, ref} = fetch_path(app, [:props, :action, :ref])
      {:error, _error, _app, _store} = submit_action(app, store, ref, 1)
  end
end
