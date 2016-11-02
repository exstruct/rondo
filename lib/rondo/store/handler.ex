defmodule Rondo.Store.Handler do
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
  use Behaviour

  defcallback create(key :: integer, props :: term) ::
    {state :: term, value :: term}
  defcallback update(state :: term, props :: term) ::
    {state :: term, value :: term}
  defcallback handle_message(state :: term, message :: term) ::
    {state :: term, value :: term}
  defcallback handle_update(state :: term, new_value :: term) ::
    {state :: term, value :: term}
end
