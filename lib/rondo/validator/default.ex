defmodule Rondo.Validator.Default do
  @behaviour Rondo.Validator

  try do
    ExJsonSchema.module_info()

    def init(schema) do
      ## TODO first convert the schema to all binary keys
      ExJsonSchema.Schema.resolve(schema)
    end

    def validate(schema, data) do
      case ExJsonSchema.Validator.validate(schema, data) do
        :ok ->
          :ok
        {:error, errors} ->
          # TODO convert these to Rondo.Validator.Error structs
          {:error, errors}
      end
    end
  catch
    _, _ ->
      def init(_) do
        nil
      end

      def validate(_, _) do
        :ok
      end
  end
end
