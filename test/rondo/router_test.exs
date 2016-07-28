defmodule Test.Rondo.Router do
  use Test.Rondo.Case

  context :router do
    alias __MODULE__.Router

    defmodule First do
      use Rondo.Component

      def render(_) do
        el("First", %{
          on_click: Router.action(:second),
          event: Router.action(:non_existant, [
            Router.event(:second)
          ])
        })
      end
    end

    defmodule Second do
      use Rondo.Component

      def render(_) do
        el("Second", %{on_click: Router.action(:first)})
      end
    end

    defmodule Router do
      use Rondo.Router

      def init(%{nil: true}) do
        nil
      end
      def init(_props) do
        :first
      end

      def route(_props, :first) do
        el(First)
      end
      def route(_props, :second) do
        el(Second)
      end
    end
  after
    "render" ->
      {app, store} = render(Router)
      assert_path app, [], %{type: "First"}

      {:ok, first_ref} = fetch_path(app, [:props, :on_click, :ref])
      {:ok, app, store} = submit_action(app, store, first_ref, nil)
      assert_path app, [], %{type: "Second"}

      {:ok, second_ref} = fetch_path(app, [:props, :on_click, :ref])
      {:ok, app, store} = submit_action(app, store, second_ref, nil)
      assert_path app, [], %{type: "First"}

      {:ok, event_ref} = fetch_path(app, [:props, :event, :ref])
      {:ok, app, _store} = submit_action(app, store, event_ref, nil)
      assert_path app, [], %{type: "Second"}

    "router struct" ->
      {app, _store} = el(Router.__router__) |> render()
      assert_path app, [], %{type: "First"}

    "nil init" ->
      {app, _store} = el(Router, %{nil: true}) |> render()
      assert_path app, [], nil
  end
end
