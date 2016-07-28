defmodule Test.Rondo.Component do
  use Test.Rondo.Case

  context :inspect do
    defmodule Component do
      use Rondo.Component

      def render(_) do
        el("Hello")
      end
    end
  after
    "inspect" ->
      {app, _store} = render(Component)
      [component] = app.components |> Map.values()
      assert inspect(component)

    "inspect pending" ->
      assert %Rondo.Component{element: el(Component)} |> inspect()

    "inspect pointer" ->
      assert %Rondo.Component.Pointer{path: []} |> inspect()
  end
end
