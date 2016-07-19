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
          on_click: ref([:counter]) |> action(Click, %{path: Foo}),
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
      manager = Manager.init(:rand.uniform())
      app = Rondo.create_application(el(Quiz))

      {diff1, app1, manager} = render_and_diff(app, manager)

      manager = Rondo.State.Store.handle_info(manager, "Hello")

      {diff2, app2, manager} = render_and_diff(app1, manager)

      action_ref = 11238785 # TODO don't hardcode this

      {:ok, app3, manager} = submit_action(app2, manager, action_ref, %{"x" => 123})

      {diff3, app3, manager} = render_and_diff(app3, manager)

      {:invalid, errors, app4, manager} = submit_action(app3, manager, action_ref, %{"x" => "foo"})

      IO.puts "!!!! ERRORS !!!!"
      IO.inspect errors
  end

  defp render_and_diff(initial, manager) do
    IO.puts "====== RENDERING ======"
    {rendered, manager} = Rondo.Application.render(initial, manager)
    IO.inspect rendered.components
    diff = Rondo.Application.diff(rendered, initial) |> Enum.to_list
    IO.puts "-------  DIFF  --------"
    IO.inspect diff
    IO.puts "\n"
    {diff, rendered, manager}
  end

  defp submit_action(app, manager, ref, data) do
    case Rondo.Application.prepare_action(app, ref, data) do
      {:invalid, errors, app} ->
        {:invalid, errors, app, manager}
      {:ok, descriptor, update_fn, app} ->
        case Rondo.State.Store.handle_action(manager, descriptor, update_fn) do
          {:ok, manager} ->
            {:ok, app, manager}
          {:error, error, manager} ->
            {:error, error, app, manager}
        end
    end
  end
end
