defmodule Test.Rondo.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use ExCheck
      use Benchfella
      import ExProf.Macro
      import Rondo.Test
      alias Rondo.Test.Store, as: TestStore
      import unquote(__MODULE__), only: [render: 1, context: 2]
    end
  end

  def render(element) do
    Rondo.Test.render(element, %Rondo.Test.Store{})
  end

  defmacro context(name, [do: body, after: tests]) do
    {name, _} = Code.eval_quoted(name)
    cname = Module.concat([__CALLER__.module, name])
    quote location: :keep do
      defmodule unquote(cname) do
        Module.register_attribute(__MODULE__, :aliases, accumulate: true)
        import Kernel, except: [defmodule: 2]
        import Test.Rondo.Case, only: [defmodule: 2]
        unquote(body)
        @before_compile Test.Rondo.Case
      end
      unquote_splicing(format_after(tests, cname, name))
    end
  end

  defp format_after(tests, cname, name) when is_list(tests) do
    tests
    |> Enum.map(fn
      {:->, _, [[test_name | args], body]} ->
        test_name = "#{name} | #{test_name}"
        quote do
          unquote(format_test([test_name | args], cname, body, Mix.env))
          unquote(format_bench(test_name, cname, body))
        end
      {:->, _, [[], body]} ->
        format_after(body, cname, name) |> hd()
    end)
  end
  defp format_after(test, cname, _name) do
    [quote do
      defmodule Test do
        use ExUnit.Case, async: false
        use ExCheck
        use unquote(cname)
        unquote(test)
      end
    end]
  end

  defp format_test(args, cname, body, :profile) do
    body = quote do
      profile do
        unquote(body)
      end
    end
    format_test(args, cname, body, :test)
  end
  defp format_test(args, cname, body, _) do
    quote do
      test unquote_splicing(args) do
        use Rondo.Element
        use unquote(cname)
        unquote(body)
        true
      end
    end
  end

  if Mix.env == :bench do
    defp format_bench(name, cname, body) do
      quote do
        bench inspect(unquote(name)) do
          use Rondo.Element
          use unquote(cname)
          unquote(body)
          true
        end
      end
    end
  else
    defp format_bench(_, _, _) do
      nil
    end
  end

  defmacro defmodule(name, [do: body]) do
    quote location: :keep do
      defmodule unquote(name) do
        unquote(body)
      end

      @aliases unquote(name)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defmacro __using__(_) do
        for alias <- @aliases do
          {:alias, [warn: false], [alias]}
        end
        ++ for alias <- @aliases do
          ## so we don't get unused alias warnings
          {:__aliases__, [], [Module.split(alias) |> List.last |> String.to_atom()]}
        end
      end
    end
  end
end

if Mix.env == :bench do
  Benchfella.start()
end
ExCheck.start()
ExUnit.start()
