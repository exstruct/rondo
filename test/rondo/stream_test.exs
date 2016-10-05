defmodule Test.Rondo.Stream do
  use Test.Rondo.Case

  context :multiple do
    defmodule SendAction do
      def affordance(_) do
        %{
          "type" => "null"
        }
      end

      def action(events, prev, _) do
        Stream.concat(prev, events)
      end
    end

    defmodule SendEvent do
      def event(events, prev, _) do
        Stream.concat(prev, events)
      end
    end

    defmodule Component do
      use Rondo.Component

      def state(_, _) do
        %{
          events: create_stream(),
        }
      end

      def render(%{events: events}) do
        el("Input", %{
          events: events,
          on_submit: ref([:events]) |> action(SendAction, [:hello], [
            ref([:events]) |> event(SendEvent, [:world]),
            ref([:events]) |> event(SendEvent, [:!])
          ])
        }, [])
      end
    end
  after
    "send events" ->
      {app, store} = render(Component)
      {:ok, sub} = fetch_path(app, [:props, :events, :id])

      {:ok, ref} = fetch_path(app, [:props, :on_submit, :ref])
      {:ok, app, _store} = submit_action(app, store, ref, nil)

      assert [:hello, :world, :!] = Rondo.fetch_streams(app) |> Map.get(sub)
  end
end
