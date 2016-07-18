defmodule Rondo.Action.Store do
  defstruct [affordances: %{},
             actions: %{},
             validators: %{},
             prev_affordances: %{}]

  def init(store = %{affordances: affordances}) do
    %{store | actions: %{}, prev_affordances: affordances}
  end

  def put(store = %{affordances: affordances, actions: actions}, component_path, action, state) do
    {schema_id, schema, schema_ref, affordances} = create_schema(affordances, action)

    case create_ref(actions, action, component_path, schema_ref, state) do
      :error ->
        # TODO should we log a warning that the state path is missing?
        {store, actions}
      {ref, actions} ->
        affordance = %Rondo.Affordance{ref: ref, schema_id: schema_id, schema: schema}
        store = %{store | actions: actions, affordances: affordances}
        {affordance, store}
    end
  end

  def finalize(s = %{affordances: affordances, validators: validators, prev_affordances: prev_affordances}) do
    {affordances, validators} = gc_affordances(affordances, validators, prev_affordances)
    %{s | affordances: affordances, validators: validators, prev_affordances: %{}}
  end

  def prepare_update(store = %{actions: actions}, ref, data) do
    case Map.fetch(actions, ref) do
      :error ->
        {:invalid, [], store}
      {:ok, %{schema_ref: schema_ref,
              component_path: component_path,
              state_descriptor: state_descriptor,
              descriptor: %{handler: handler,
                            props: props,
                            state_path: state_path}}} ->
        # TODO implement the events

        {validator, store} = init_validator(store, schema_ref)
        case validate(validator, data) do
          {:error, errors} ->
            {:invalid, errors, store}
          :ok ->
            update_fn = fn(state) ->
              call(handler, :action, [props, state, data])
            end
           {:ok, component_path, state_path, state_descriptor, update_fn, store}
        end
    end
  end

  defp create_schema(affordances, %{handler: handler, props: props}) do
    key = {handler, props}
    case Map.fetch(affordances, key) do
      {:ok, {id, schema}} ->
        {id, schema, key, affordances}
      :error ->
        schema = call(handler, :affordance, [props])
        id = hash(schema)
        affordances = Map.put(affordances, key, {id, schema})
        {id, schema, key, affordances}
    end
  end

  defp create_ref(actions, action, component_path, schema_ref, state) do
    case fetch_state_descriptor(state, action) do
      :error ->
        nil
      {:ok, state_descriptor} ->
        ref = hash({component_path, action})
        actions = Map.put(actions, ref, %{
          descriptor: action,
          state_descriptor: state_descriptor,
          component_path: component_path,
          schema_ref: schema_ref
        })
        {ref, actions}
    end
  end

  defp fetch_state_descriptor(%{children: descriptors}, %{state_path: state_path}) do
    Map.fetch(descriptors, state_path)
  end

  defp init_validator(store = %{validators: validators, affordances: affordances}, schema_ref) do
    case Map.fetch(validators, schema_ref) do
      {:ok, validator} ->
        {validator, store}
      :error ->
        {_, schema} = Map.fetch!(affordances, schema_ref) || %{}
        validator = apply(app_validator, :init, [schema])
        store = %{store | validators: Map.put(validators, schema_ref, validator)}
        {validator, store}
    end
  end

  defp app_validator() do
    Application.get_env(Rondo, :validator, Rondo.Validator.Default)
  end

  defp validate(validator, data) do
    apply(app_validator, :validate, [validator, data])
  end

  defp call(handler, fun, args) do
    apply(handler, fun, args)
  end

  defp hash(contents) do
    :erlang.phash2(contents) ## TODO pick a stronger hash?
  end

  defp gc_affordances(affordances, validators, prev_affordances) do
    Enum.reduce(prev_affordances, {affordances, validators}, fn({_, {id, _}}, {affordances, validators}) ->
      if Map.has_key?(affordances, id) do
        {affordances, validators}
      else
        {Map.delete(affordances, id), Map.delete(validators, id)}
      end
    end)
  end
end

defimpl Rondo.Diffable, for: Rondo.Action.Store do
  def diff(curr, prev, path) do
    Rondo.Diff.diff(format(curr), format(prev), path)
  end

  defp format(%{affordances: affordances}) do
    Map.values(affordances) |> :maps.from_list()
  end
end
