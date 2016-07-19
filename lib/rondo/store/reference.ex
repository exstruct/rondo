defmodule Rondo.Store.Reference do
  defstruct [:state_path, :fallback]

  defmacro __using__(_) do
    quote do
      import Rondo.Store.Reference, only: [ref: 1, ref: 2]
    end
  end

  defmodule Error do
    defexception [:reference, :component_path, :component_type]

    def message(%{reference: %{state_path: state_path}, component_type: type, component_path: path}) do
      "Trying to refer to immutable or missing state #{inspect(state_path)} in #{inspect(type)} at #{inspect(path)}"
    end
  end

  @required __MODULE__.REQUIRED

  def ref(state_path) when is_list(state_path) do
    %__MODULE__{state_path: state_path, fallback: @required}
  end
  def ref(state_path, fallback) when is_list(fallback) do
    ref(state_path, ref(fallback))
  end
  def ref(state_path, fallback) do
    %__MODULE__{state_path: state_path, fallback: fallback}
  end

  def resolve(ref, state, mode \\ :descriptor)
  def resolve(%{state_path: state_path, fallback: fallback}, state, mode) do
    case Map.fetch(state, state_path) do
      {:ok, %__MODULE__{} = ref} ->
        case resolve(ref, state, mode) do
          {:ok, value} ->
            {:ok, value}
          :error ->
            resolve(fallback, state, mode)
        end
      {:ok, %Rondo.Store{} = store} when mode == :descriptor ->
        {:ok, store}
      {:ok, value} when mode == :value ->
        {:ok, value}
      _ when fallback == @required ->
        :error
      _ when fallback == nil ->
        {:ok, nil}
      _ ->
        resolve(fallback, state, mode)
    end
  end
end
