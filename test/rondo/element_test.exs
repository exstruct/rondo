defmodule Test.Rondo.Element do
  use Test.Rondo.Case

  context :binary_element do
    # n/a
  after
    "name" ->
      {app, _store} = el("Text") |> render()

      assert_path app, [], %{type: "Text"}

    "with props" ->
      {app, _store} = el("Text", %{foo: "bar"}) |> render()

      assert_path app, [:props, :foo], "bar"
  end

  context :inspect do
    # n/a
  after
    "with children" ->
      assert %Rondo.Element{type: "Foo", children: ["Hello, ", "World", "!"]} |> inspect()
  end
end
