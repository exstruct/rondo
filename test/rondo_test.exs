defmodule Test.Rondo do
  use Test.Rondo.Case

  context Foo do
    defmodule Manager do
      defstruct [:number]

      defimpl Rondo.Manager do
        def create(%{number: number} = manager, c_path, id, descriptor) do
          {number, manager}
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
        put_in(state, [:session, :coord], x)
      end
    end

    defmodule NextLevel do
      use Rondo.Component

      def render(props, _) do
        el("Text", %{
            on_click: action(Click, %{})
           }, [props[:text]])
      end
    end

    defmodule Nested do
      use Rondo.Component

      def init(_props, context) do
        %{
          next: context[:number]
        }
      end

      def render(_, %{next: next}) do
        el(NextLevel, %{text: next})
      end
    end

    defmodule Quiz do
      use Rondo.Component

      def init(_props, _context) do
        %{
          root: create_store(%{}, Quiz123),
          local: create_store(%{})
        }
      end

      def context(_props, state) do
        %{
          number: state[:local]
        }
      end

      def render(props, _) do
        el(Nested, nil, props.children)
      end
    end
  after
    "foo" ->
      manager = %Manager{number: :rand.uniform()}
      app = Rondo.create_application(el(Quiz), manager)
      {diff1, app1} = render_and_diff(app)
      app1 = update_manager(app1, fn(manager) ->
        %{manager | number: "Hello"}
      end)

      {diff2, app2} = render_and_diff(app1)
  end

  defp render_and_diff(initial) do
    IO.puts "====== RENDERING ======"
    rendered = Rondo.render(initial)
    IO.inspect rendered.components
    {diff, app} = Rondo.diff(rendered, initial)
    IO.puts "-------  DIFF  --------"
    IO.inspect diff
    IO.puts "\n"
    {diff, app}
  end

  defp update_manager(app, manager) do
    Rondo.Application.update_manager(app, manager)
  end
end
