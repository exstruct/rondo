defmodule Test.Rondo.Diff do
  use Test.Rondo.Case
  import Rondo.Element

  context :simple do
    defmodule Component do
      use Rondo.Component

      def render(%{children: children}) do
        el("Foo", nil, children)
      end
    end
  after
    "remove" ->
      {first, _store} =
        el(Component, nil, [
          el("First"),
          el("Second")
        ]) |> render()

      {second, _store} =
        el(Component, nil, [
          el("Second")
        ]) |> render()

      # TODO this should really just do a copy-remove
      assert %{} =
        Rondo.diff(second, first)

    "switch" ->
      {first, _store} =
        el(Component, nil, [
          el("First"),
          el("Second")
        ]) |> render()

      {second, _store} =
        el(Component, nil, [
          el("Second"),
          el("First")
        ]) |> render()

      # TODO this should be two copies
      assert %{} =
        Rondo.diff(second, first)

    "insert" ->
      {first, _store} =
        el(Component, nil, [
          el("First"),
          el("Second")
        ]) |> render()

      {second, _store} =
        el(Component, nil, [
          el("First"),
          el("First-and-a-half"),
          el("Second")
        ]) |> render()

      assert %{} =
        Rondo.diff(second, first)

    "keyed" ->
      {first, _store} =
        el(Component, nil, [
          el("First", %{key: "f"}, [1]),
          el("Second", %{key: "s"}, [1])
        ]) |> render()

      {second, _store} =
        el(Component, nil, [
          el("Second", %{key: "s"}, [2]),
          el("First", %{key: "f"}, [2])
        ]) |> render()

      assert %{} =
        Rondo.diff(second, first)
  end

  context :recursive do
    defmodule Action do
      def affordance(count) do
        %{
          "type" => "array",
          "minItems" => count
        }
      end

      def action(_, state, _) do
        state
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(props, _) do
        %{
          count: props.count,
          value: create_store()
        }
      end

      def render(%{count: 0}) do
        el("Hello!")
      end
      def render(%{count: count}) do
        el("Container", %{
          on_click: action(ref([:value]), Action, count)
        }, [
          el(__MODULE__, %{count: count - 1})
        ])
      end
    end
  after
    property :diff_patch do
      for_all {first, second} in {pos_integer, pos_integer} do
        {prev, store} = el(Component, %{count: first}) |> render()

        {curr, _store} = render(%{prev | entry: el(Component, %{count: second})}, store)

        diff = Rondo.diff(curr, prev)

        {new, _store} = el(Component, %{count: second}) |> render()

        # TODO validate the diff is correct by comparing applying the patches and comparing it to new
        _diff = diff
        _new = new

        true
      end
    end
  end
end
