defmodule Rondo.Validator do
  use Behaviour

  @type schema :: map | nil
  @type data :: any

  defcallback init(schema)
  defcallback validate(schema, data)
end
