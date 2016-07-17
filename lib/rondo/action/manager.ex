defmodule Rondo.Action.Manager do
  defstruct [affordances: %{},
             actions: %{},
             validators: %{},
             prev_affordances: %{}]

  def init(manager = %{affordances: affordances}) do
    %{manager | actions: %{}, prev_affordances: affordances}
  end

  def put(manager = %{affordances: affordances, actions: actions}, component_path, action) do
    {schema_id, schema, affordances} = create_schema(affordances, action)
    {ref, actions} = create_ref(actions, action, component_path, schema_id)

    {%Rondo.Affordance{ref: ref, schema_id: schema_id, schema: schema}, %{manager | actions: actions, affordances: affordances}}
  end

  defp create_schema(affordances, %{handler: handler, props: props}) do
    key = {handler, props}
    case Map.fetch(affordances, key) do
      {:ok, {id, schema}} ->
        {id, schema, affordances}
      :error ->
        schema = call(handler, :affordance, [props])
        id = hash(schema)
        affordances = Map.put(affordances, key, {id, schema})
        {id, schema, affordances}
    end
  end

  defp create_ref(actions, action, component_path, schema_id) do
    ref = hash({component_path, action})
    actions = Map.put(actions, ref, %{
      descriptor: action,
      component_path: component_path,
      schema_id: schema_id
    })
    {ref, actions}
  end

  defp call(handler, fun, args) do
    apply(handler, fun, args)
  end

  defp hash(contents) do
    :erlang.phash2(contents) ## TODO pick a stronger hash?
  end

  def finalize(m = %{affordances: affordances, validators: validators, prev_affordances: prev_affordances}) do
    {affordances, validators} = Enum.reduce(prev_affordances, {affordances, validators}, fn({_, {id, _}}, {affordances, validators}) ->
      if Map.has_key?(affordances, id) do
        {affordances, validators}
      else
        {Map.delete(affordances, id), Map.delete(validators, id)}
      end
    end)
    %{m | affordances: affordances, validators: validators, prev_affordances: %{}}
  end
end

defimpl Rondo.Diff, for: Rondo.Action.Manager do
  def diff(curr, prev, path) do
    Rondo.Diff.diff(format(curr), format(prev), path)
  end

  defp format(%{affordances: affordances}) do
    Map.values(affordances) |> :maps.from_list()
  end
end
