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

    defmodule Event do
      def event(_, state, input) do
        state + input
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(_, _) do
        %{
          count: create_store(0),
          event_count: create_store(0)
        }
      end

      def render(%{count: count, event_count: event_count}) do
        el("Input", %{
          on_submit: action(ref([:count]), Increment, %{}, [
            event(ref([:event_count]), Event)
          ])
        }, [count, event_count])
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
              {:ok, event_value} = fetch_path(app, [1])

              {[value == expected,
                event_value == expected], {app, store}}
            {:invalid, _, app, store} ->
              {[false], {app, store}}
          end
        end)
        |> Enum.all?()
      end
    end
  end

  context :invalid do
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
          count: create_store(0),
        }
      end

      def render(%{count: count}) do
        el("Input", %{
          on_submit: action(ref([:count]), Increment)
        }, [count])
      end
    end
  after
    "invalid input" ->
      {app, store} = render(Component)

      {:ok, ref} = fetch_path(app, [:props, :on_submit, :ref])

      assert {:invalid, _errors, _app, _store} = submit_action(app, store, ref, "Foo")

    "non-existant" ->
      {app, store} = render(Component)

      assert {:invalid, _errors, _app, _store} = submit_action(app, store, -1, 1)
  end

  context :nil_ref do
    defmodule Component do
      use Rondo.Component

      def render(_) do
        el("Input", %{
          on_submit: action(nil, Action, %{}, [
            event(nil, Event, %{})
          ])
        })
      end
    end
  after
    "render" ->
      {app, _store} = render(Component)

      assert {:ok, nil} = fetch_path(app, [:props, :on_submit])
  end
end
