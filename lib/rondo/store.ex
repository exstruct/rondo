defmodule Rondo.Store do
  require Logger

  defmacro __using__(_) do
    quote do
      use Rondo.Store.Instance
    end
  end

  defstruct [ephemeral: %{}, instances: %{}]

  def new(_opts \\ %{}) do
    %__MODULE__{}
  end

  def initialize(store) do
    # TODO garbage collect old values
    store
  end

  def mount(%{ephemeral: ephemeral} = store, %{type: :ephemeral, props: props} = descriptor) do
    key = descriptor_key(descriptor)
    prop_hash = :erlang.phash2(props)
    case Map.fetch(ephemeral, key) do
      {:ok, {^prop_hash, value}} ->
        {value, store}
      _ when is_function(props, 0) ->
        value = props.()
        ephemeral = Map.put(ephemeral, key, {prop_hash, value})
        {value, %{store | ephemeral: ephemeral}}
      _ ->
        ephemeral = Map.put(ephemeral, key, {prop_hash, props})
        {props, %{store | ephemeral: ephemeral}}
    end
  end
  def mount(%{instances: instances} = store, %{type: type, props: props} = descriptor) do
    key = descriptor_key(descriptor)
    case Map.fetch(instances, key) do
      {:ok, %{type: ^type, props: ^props, value: value}} ->
        {value, store}
      {:ok, %{type: ^type, instance: instance, value: value}} ->
        {value, instance} = type.update(instance, value, props)
        descriptor = %{type: type, props: props, value: value, instance: instance}
        {value, %{store | instances: Map.put(instances, key, descriptor)}}
      {:ok, %{type: t, instance: prev}} ->
        t.stop(prev)
        {value, instance} = type.create(props, key)
        descriptor = %{type: type, props: props, value: value, instance: instance}
        {value, %{store | instances: Map.put(instances, key, descriptor)}}
      :error ->
        {value, instance} = type.create(props, key)
        descriptor = %{type: type, props: props, value: value, instance: instance}
        {value, %{store | instances: Map.put(instances, key, descriptor)}}
    end
  end

  def finalize(store) do
    store
  end

  def handle_info(%{instances: instances} = store, {key, value} = msg) do
    case Map.fetch(instances, key) do
      {:ok, %{type: type, instance: instance} = descriptor} ->
        {value, instance} = type.handle_message(instance, value)
        descriptor = %{descriptor | value: value, instance: instance}
        %{store | instances: Map.put(instances, key, descriptor)}
      _ ->
        Logger.warn("Unhandled message: #{inspect(msg)}")
        store
    end
  end
  def handle_info(store, msg) do
    Logger.warn("Unhandled message: #{inspect(msg)}")
    store
  end

  def handle_action(store, %{type: :ephemeral} = descriptor, update_fn) do
    {_, %{ephemeral: ephemeral} = store} = mount(store, descriptor)
    key = descriptor_key(descriptor)

    {:ok, {props_hash, prev}} = Map.fetch(ephemeral, key)
    value = update_fn.(prev)
    ephemeral = Map.put(ephemeral, key, {props_hash, value})
    {:ok, %{store| ephemeral: ephemeral}}
  end

  def to_term(%{ephemeral: ephemeral}) do
    ephemeral
  end

  def from_term(store, ephemeral) do
    %{store | ephemeral: ephemeral}
  end

  defp descriptor_key(%{component_type: ct, component_path: cp, state_path: sp}) do
    :erlang.phash2({ct, cp, sp})
  end
end
