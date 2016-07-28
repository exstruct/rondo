defmodule Test.Rondo.Test do
  use Test.Rondo.Case

  context :render_shallow do
    defmodule First do
      use Rondo.Component

      def render(_) do
        throw :IT_RENDERED
      end
    end

    defmodule Second do
      use Rondo.Component

      def render(_) do
        el(First)
      end
    end
  after
    "call" ->
      {app, _store} = render_shallow(Second, %TestStore{})

      assert_path app, [], %{type: First}
  end
end
