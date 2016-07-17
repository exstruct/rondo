defmodule Test.Rondo do
  use Test.Rondo.Case

  context Foo do
    defmodule Manager do
      defstruct [:message]

      def init(message) do
        %__MODULE__{message: message}
      end

      defimpl Rondo.Manager do
        def mount(%{message: message} = manager, c_path, id, descriptor) do
          {message, manager}
        end

        def handle_info(manager, message) do
          %{manager | message: message}
        end
      end
    end

    defmodule Click do
      use Rondo.Action

      def affordance(_props) do
        %{
          type: "object",
          properties: %{
            x: %{
              type: "number"
            }
          }
        }
      end

      def action(_props, state, %{"x" => x}) do
        put_in(state, ["x"], x)
      end
    end

    defmodule NextLevel do
      use Rondo.Component

      def render(%{text: text}) do
        el("Text", %{
              on_click: action(Click, ["my_state"], %{}),
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
          next: context[:number]
        }
      end

      def render(%{next: next}) do
        el(NextLevel, %{text: next})
      end
    end

    defmodule Quiz do
      use Rondo.Component

      def state(%{children: children}, _context) do
        %{
          root: create_store(%{}, Quiz123),
          local: create_store(%{}),
          children: children
        }
      end

      def context(state) do
        %{
          number: state[:local]
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

      manager = Rondo.Manager.handle_info(manager, "Hello")

      {diff2, app2, maanger} = render_and_diff(app1, manager)
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
end
