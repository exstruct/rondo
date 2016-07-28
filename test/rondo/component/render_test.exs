defmodule Test.Rondo.Component.Render do
  use Test.Rondo.Case

  context :basic do
    defmodule Component do
      use Rondo.Component

      def render(_) do
        el("Text")
      end
    end
  after
    "render" ->
      {app, _store} = render(Component)

      assert_path app, [], %{type: "Text"}
  end

  context :reference do
    defmodule First do
      use Rondo.Component

      def render(_) do
        el("Text")
      end
    end

    defmodule Second do
      use Rondo.Component

      def render(_) do
        el(First)
      end
    end
  after
    "render" ->
      {app, _store} = render(Second)

      assert_path app, [], %{type: "Text"}
  end

  context :props do
    defmodule Component do
      use Rondo.Component

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end
  after
    "render" ->
      {app, _store} = el(Component, %{name: "Foo"}) |> render()

      assert_path app, [], %{type: "Text"}
      assert_path app, [0], "Foo"

    "wrong props" ->
      assert_raise FunctionClauseError, fn ->
        el(Component) |> render()
      end
  end
end
