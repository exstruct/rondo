defmodule Test.Rondo.Diff do
  use Test.Rondo.Case
  import Rondo.Element

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
        _diff = Enum.to_list(diff)
        _new = new

        true
      end
    end
  end
end
