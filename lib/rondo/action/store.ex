defmodule Rondo.Action.Store do
  defstruct [affordances: %{},
             actions: %{},
             validators: %{},
             prev_affordances: %{}]

  alias Rondo.Action.Handler

  def init(store = %{affordances: affordances}) do
    %{store | actions: %{}, prev_affordances: affordances}
  end

  def put(store = %{affordances: affordances, actions: actions}, action) do
    {schema_id, schema, schema_ref, affordances} = create_schema(affordances, action)
    {ref, actions} = create_ref(actions, action, schema_ref)
    affordance = %Rondo.Affordance{ref: ref, schema_id: schema_id, schema: schema}
    store = %{store | actions: actions, affordances: affordances}
    {affordance, store}
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
              events: events,
              action: %{handler: handler,
                        props: props,
                        reference: state_descriptor}}} ->
        {validator, store} = init_validator(store, schema_ref)
        case validate(validator, data) do
          {:error, errors} ->
            {:invalid, errors, store}
          :ok ->
            update_fn = &Handler.action(handler, props, &1, data)
            events = Enum.map(events, &(&1.(data)))
            {:ok, [{state_descriptor, update_fn} | events], store}
        end
    end
  end

  defp create_schema(affordances, %{handler: handler, props: props}) do
    key = {handler, props}
    case Map.fetch(affordances, key) do
      {:ok, {id, schema}} ->
        {id, schema, key, affordances}
      :error ->
        schema = Handler.affordance(handler, props)
        id = hash(schema)
        affordances = Map.put(affordances, key, {id, schema})
        {id, schema, key, affordances}
    end
  end

  defp create_ref(actions, action, schema_ref) do
    ref = hash(action)
    actions = Map.put(actions, ref, %{
      events: Enum.map(action.events, &init_events/1),
      action: action,
      schema_ref: schema_ref
    })
    {ref, actions}
  end

  defp init_events(%{reference: descriptor, handler: handler, props: props}) do
    fn(data) ->
      {descriptor, &Rondo.Event.Handler.event(handler, props, &1, data)}
    end
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
