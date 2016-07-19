defmodule Test.Rondo do
  use Test.Rondo.Case

  context Foo do
    defmodule Manager do
      defstruct [:message]

      def init(message) do
        %__MODULE__{message: message}
      end

      defimpl Rondo.State.Store do
        def mount(%{message: message} = manager, descriptor) do
          {message, manager}
        end

        def handle_info(manager, message) do
          %{manager | message: message}
        end

        def handle_action(manager, descriptor, update_fn) do
          {:ok, %{manager | message: update_fn.(%{})}}
        end
      end
    end

    defmodule Click do
      use Rondo.Action

      def affordance(_props) do
        %{
          "type" => "object",
          "properties" => %{
            "x" => %{
              "type" => "number"
            }
          }
        }
      end

      def action(_props, state, %{"x" => x}) do
        x
      end
    end

    defmodule CounterLogger do
      use Rondo.Event

      def event(props, state) do
        IO.inspect {:LOGGER, props, state}
        state
      end
    end

    defmodule NextLevel do
      use Rondo.Component

      def state(props, context) do
        %{
          my_state: create_store(),
          text: props.text,
          counter: context[:counter]
        }
      end

      def render(%{text: text}) do
        el("Text", %{
          on_click: ref([:counter])
            |> action(Click, %{path: Foo})
            |> event(ref([:counter]), CounterLogger),
          foo: if is_binary(text) do
            123
          end
        }, [
          text
        ])
      end
    end

    defmodule Nested do
      use Rondo.Component

      def state(_props, context) do
        %{
          counter: context[:counter]
        }
      end

      def render(%{counter: counter}) do
        el(NextLevel, %{text: counter})
      end
    end

    defmodule Quiz do
      use Rondo.Component

      def state(%{children: children}, _context) do
        %{
          root: create_store(%{}, Quiz123),
          local: create_store(%{}),
          children: children,
          foo: ref([:local])
        }
      end

      def context(state) do
        %{
          counter: ref([:foo])
        }
      end

      def render(state) do
        el("Foo", nil, [
          el(Nested, nil, state.children)
        ])
      end
    end
  after
    "foo" ->
      store = Manager.init(:rand.uniform())
      element = el(Quiz)

      app = Rondo.create_application(element)

      {diff1, app1, store} = render_and_diff(app, store)

      store = Rondo.State.Store.handle_info(store, "Hello")

      {diff2, app2, store} = render_and_diff(app1, store)

      {:ok, %{props: %{on_click: %{ref: action_ref}}}} = Rondo.Test.fetch_path(app2, [0])

      {:ok, _, store} = Rondo.Test.submit_action(app2, store, action_ref, %{"x" => 123})

      {diff3, app3, store} = render_and_diff(app2, store)

      {:invalid, errors, app4, store} = Rondo.Test.submit_action(app3, store, action_ref, %{"x" => "foo"})

      IO.puts "!!!! ERRORS !!!!"
      IO.inspect errors
  end

  defp render_and_diff(initial, store) do
    IO.puts "====== RENDERING ======"
    {rendered, store} = Rondo.Application.render(initial, store)
    IO.inspect rendered.components
    diff = Rondo.Application.diff(rendered, initial) |> Enum.to_list
    IO.puts "-------  DIFF  --------"
    IO.inspect diff
    IO.puts "\n"
    {diff, rendered, store}
  end
end
