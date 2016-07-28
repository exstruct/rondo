defmodule Test.Rondo.Action do
  use Test.Rondo.Case

  context :increment do
    defmodule Increment do
      def affordance(_) do
        %{
          "type" => "integer"
        }
      end

      def action(_, state, input) do
        state + input
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(_, _) do
        %{
          count: create_store(0)
        }
      end

      def render(%{count: count}) do
        el("Input", %{
          on_submit: action(ref([:count]), Increment)
        }, [count])
      end
    end
  after
    property :increment do
      {app, store} = render(Component)

      assert_path app, [0], 0

      {:ok, ref} = fetch_path(app, [:props, :on_submit, :ref])

      for_all integers in list(int) do
        integers
        |> Stream.scan({0, 0}, fn(int, {_, total}) ->
          {int, total + int}
        end)
        |> Stream.transform({app, store}, fn({amount, expected}, {app, store}) ->
          case submit_action(app, store, ref, amount) do
            {:ok, app, store} ->
              {:ok, value} = fetch_path(app, [0])

              {[value == expected], {app, store}}
            {:invalid, _, app, store} ->
              {[false], {app, store}}
          end
        end)
        |> Enum.all?()
      end
    end
  end
end
