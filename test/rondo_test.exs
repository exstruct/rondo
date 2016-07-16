defmodule Test.Rondo do
  use Test.Rondo.Case

  context Foo do
    defmodule Router do
      # use Rondo.Router
      # route "/", Quiz
    end

    defmodule Click do
      use Rondo.Action

      def schema do
        %{
          type: "object",
          properties: %{
            x: %{
              type: "number"
            }
          }
        }
      end

      def handle(state, %{"x" => x}) do
        put_in(state, [:session, :coord], x)
      end
    end

    defmodule NextLevel do
      use Rondo.Component

      def render(_, _) do
        el("Text")
      end
    end

    defmodule Nested do
      use Rondo.Component

      def render(_, _) do
        [1, el(NextLevel)]
      end
    end

    defmodule Quiz do
      use Rondo.Component

      def init(_props, _context) do
        #user = create_store(auth(Facebook))
        %{
          #answers: create_store({Quiz123, user.provider, user.id}),
          #root: create_store(Quiz123),
          #router: Router.create_store()
          #user: user
        }
      end

      def context(_props, _state) do
        %{
          #router: state.router
        }
      end

      def render(props, _) do
        el(Nested, nil, props.children)
      end
    end
  after
    "foo" ->
      app = Rondo.create_app(el(Quiz, %{path: "/"}, [
              el(Quiz, %{path: "/foo"})
            ]))
      Rondo.Application.render(app)
      |> IO.inspect
  end
end
