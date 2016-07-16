defmodule Test.Rondo.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import unquote(__MODULE__), only: [context: 2]
    end
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
      unquote(for {:->, _, [[test_name | args], body]} <- tests do
        quote do
          test unquote_splicing(["#{test_name} | #{inspect(name)}" | args]) do
            use Rondo.Element
            use unquote(cname)
            unquote(body)
            true
          end
        end
      end)
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

ExUnit.start()
