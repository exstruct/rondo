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
end
