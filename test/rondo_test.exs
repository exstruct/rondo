defmodule Test.Rondo do
  use Test.Rondo.Case

  context :create_application do
    # n/a
  after
    "binary" ->
      assert Rondo.create_application("Text")

    "module" ->
      assert Rondo.create_application(MyComponent)

    "binary, props" ->
      assert Rondo.create_application("Text", %{})

    "module, props" ->
      assert Rondo.create_application(MyComponent, %{})
  end
end
