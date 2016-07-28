defmodule Test.Rondo.Component.Context do
  use Test.Rondo.Case

  context :basic do
    defmodule First do
      use Rondo.Component

      def state(_, context) do
        context
      end

      def render(%{name: name}) do
        el("Text", nil, [name])
      end
    end

    defmodule Second do
      use Rondo.Component

      def state(props, _) do
        %{
          name: props[:name] || "Joe"
        }
      end

      def context(state) do
        state
      end

      def render(_) do
        el(First)
      end
    end
  after
    "render" ->
      {app, _store} = render(Second)

      assert_path app, [], %{type: "Text"}
      assert_path app, [0], "Joe"

    "with props" ->
      {app, _store} = el(Second, %{name: "Robert"}) |> render()

      assert_path app, [0], "Robert"
  end
end
