defmodule Rondo do
  alias Rondo.Application
  alias Rondo.Element

  def create_application(element) when is_atom(element) or is_binary(element) do
    element
    |> Element.el()
    |> create_application()
  end
  def create_application(element) do
    element
    |> Application.init()
  end

  def create_application(element, props) when is_atom(element) or is_binary(element) do
    element
    |> Element.el(props)
    |> create_application()
  end

  def render(app, store, context \\ %{}) do
    Rondo.Application.render(app, store, context)
  end

  def diff(current, previous) do
    Rondo.Diff.diff(current, previous)
    |> :lists.flatten()
  end

  def submit_action(app, store, ref, data) do
    case Rondo.Application.prepare_action(app, ref, data) do
      {:invalid, errors, app} ->
        {:invalid, errors, app, store}
      {:ok, descriptors, app} ->
        case apply_descriptors(descriptors, store, %{}) do
          {:ok, store, streams} ->
            {:ok, %{app | streams: streams}, store}
          {:error, error, store} ->
            {:error, error, app, store}
        end
    end
  end

  def fetch_streams(%{streams: streams}) do
    Enum.reduce(streams, %{}, fn({key, value}, acc) ->
      value = Enum.to_list(value)
      Map.put(acc, key, value)
    end)
  end

  defp apply_descriptors([], store, streams) do
    {:ok, store, streams}
  end
  defp apply_descriptors([{%Rondo.Stream{id: id}, update_fn} | descriptors], store, streams) do
    prev = Map.get(streams, id, [])
    events = update_fn.(prev)
    streams = Map.put(streams, id, events)
    apply_descriptors(descriptors, store, streams)
  end
  defp apply_descriptors([{descriptor, update_fn} | descriptors], store, streams) do
    case Rondo.State.Store.handle_action(store, descriptor, update_fn) do
      {:ok, store} ->
        apply_descriptors(descriptors, store, streams)
      {:error, error, store} ->
        {:error, error, store}
    end
  end
end
