defmodule Rondo.Action.Manager do
  defstruct [affordances: %{},
             actions: %{},
             validators: %{},
             prev_affordances: %{}]

  def init(manager = %{affordances: affordances}) do
    %{manager | actions: %{}, prev_affordances: affordances}
  end

  def put(manager = %{affordances: affordances, actions: actions}, component_path, action) do
    {schema_id, schema, schema_ref, affordances} = create_schema(affordances, action)
    {ref, actions} = create_ref(actions, action, component_path, schema_ref)

    {%Rondo.Affordance{ref: ref, schema_id: schema_id, schema: schema}, %{manager | actions: actions, affordances: affordances}}
  end

  def finalize(m = %{affordances: affordances, validators: validators, prev_affordances: prev_affordances}) do
    {affordances, validators} = gc_affordances(affordances, validators, prev_affordances)
    %{m | affordances: affordances, validators: validators, prev_affordances: %{}}
  end

  def prepare_update(manager = %{actions: actions}, ref, data) do
    case Map.fetch(actions, ref) do
      :error ->
        {:invalid, [], manager}
      {:ok, %{schema_ref: schema_ref,
              component_path: component_path,
              descriptor: %{handler: handler,
                            props: props,
                            state_path: state_path}}} ->
        # TODO implement the events

        {validator, manager} = init_validator(manager, schema_ref)
        case validate(validator, data) do
          {:error, errors} ->
            {:invalid, errors, manager}
          :ok ->
            update_fn = fn(state) ->
              call(handler, :action, [props, state, data])
            end
           {:ok, component_path, state_path, update_fn, manager}
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

  defp create_ref(actions, action, component_path, schema_ref) do
    ref = hash({component_path, action})
    actions = Map.put(actions, ref, %{
      descriptor: action,
      component_path: component_path,
      schema_ref: schema_ref
    })
    {ref, actions}
  end

  defp init_validator(manager = %{validators: validators, affordances: affordances}, schema_ref) do
    case Map.fetch(validators, schema_ref) do
      {:ok, validator} ->
        {validator, manager}
      :error ->
        {_, schema} = Map.fetch!(affordances, schema_ref) || %{}
        validator = apply(app_validator, :init, [schema])
        {validator, %{manager | validators: Map.put(validators, schema_ref, validator)}}
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

defimpl Rondo.Diffable, for: Rondo.Action.Manager do
  def diff(curr, prev, path) do
    Rondo.Diff.diff(format(curr), format(prev), path)
  end

  defp format(%{affordances: affordances}) do
    Map.values(affordances) |> :maps.from_list()
  end
end
