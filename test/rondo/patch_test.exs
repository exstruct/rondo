defmodule Test.Rondo.Patch do
  use ExUnit.Case

  Module.register_attribute(__MODULE__, :patch_tests, accumulate: true)

  tests = "#{__DIR__}/patch/json-patch-test-suite.json"
  |> File.read!()
  |> :jsx.decode([:return_maps])

  for %{"doc" => prev, "expected" => curr} = test <- tests do
    name = test["comment"] || "#{inspect(prev)} -> #{inspect(curr)}"
    patch = Rondo.diff(curr, prev)
    @patch_tests %{
      "name" => name,
      "doc" => prev,
      "patch" => patch.doc,
      "expected" => curr
    }

    test name do
      prev = unquote(Macro.escape(prev))
      expected = unquote(Macro.escape(curr))
      patch = unquote(Macro.escape(patch))

      actual = Rondo.Patch.apply(patch, prev)

      assert expected == actual
    end
  end

  setup_all do
   on_exit fn ->
     tests = @patch_tests |> :jsx.encode(indent: 2, space: 1)
     File.write!("#{__DIR__}/patch/suite.json", tests)
   end
   :ok
  end
end
