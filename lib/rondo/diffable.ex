defprotocol Rondo.Diffable do
  @fallback_to_any true
  def diff(current, prev, path)
end

defimpl Rondo.Diffable, for: Map do
  import Rondo.Operation

  def diff(curr, prev, path) do
    {v_dict, k_dict} = init_dict(prev)
    acc = first_pass(curr, prev, path, v_dict, k_dict)
    :maps.fold(fn(key, curr_v, acc) ->
      case Map.fetch(prev, key) do
        :error ->
          case Map.fetch(v_dict, curr_v) do
            :error ->
              [acc, replace([key | path], curr_v)]
            {:ok, cp_key} ->
              [acc, copy([cp_key | path], [key | path])]
          end
        _ ->
          acc
      end
    end, acc, curr)
  end

  defp first_pass(curr, prev, path, v_dict, k_dict) do
    :maps.fold(fn(key, prev_v, acc) ->
      case Map.fetch(curr, key) do
        :error ->
          [acc, remove([key | path])]
        {:ok, ^prev_v} ->
          acc
        {:ok, %Rondo.Element{key: curr_k} = curr_v} ->
          case Map.fetch(k_dict, curr_k) do
            :error ->
              [acc, Rondo.Diff.diff(curr_v, prev_v, [key | path])]
            {:ok, ^key} ->
              [acc, Rondo.Diff.diff(curr_v, prev_v, [key | path])]
            {:ok, cp_key} ->
              case prev_v do
                %Rondo.Element{props: prev_p, children: prev_c} ->
                  op = copy([cp_key | path], [key | path])
                  prev_v = %{curr_v | props: prev_p, children: prev_c}
                  diff = Rondo.Diffable.diff(curr_v, prev_v, [key | path])
                  [acc, op, diff]
                _ ->
                  [acc, replace([key | path], curr_v)]
              end
          end
        {:ok, curr_v} ->
          case Map.fetch(v_dict, curr_v) do
            :error ->
              [acc, Rondo.Diff.diff(curr_v, prev_v, [key | path])]
            {:ok, cp_key} ->
              [acc, copy([cp_key | path], [key | path])]
          end
      end
    end, [], prev)
  end

  defp init_dict(prev) do
    :maps.fold(fn
      (key, %Rondo.Element{key: el_key} = value, {v_dict, k_dict}) when not is_nil(el_key) ->
        v_dict = Map.put(v_dict, value, key)
        k_dict = Map.put(k_dict, el_key, key)
        {v_dict, k_dict}
      (key, value, {v_dict, k_dict}) ->
        v_dict = Map.put(v_dict, value, key)
        {v_dict, k_dict}
    end, {%{}, %{}}, prev)
  end
end

defimpl Rondo.Diffable, for: List do
  def diff(curr, prev, path) do
    curr = with_index(curr, 0, %{})
    prev = with_index(prev, 0, %{})
    Rondo.Diffable.Map.diff(curr, prev, path)
  end

  defp with_index([], _, acc) do
    acc
  end
  defp with_index([item | list], i, acc) do
    acc = Map.put(acc, i, item)
    with_index(list, i + 1, acc)
  end
end

defimpl Rondo.Diffable, for: [Atom, BitString, Integer, Float] do
  import Rondo.Operation

  def diff(current, current, _) do
    []
  end
  def diff(current, _, path) do
    [replace(path, current)]
  end
end

defimpl Rondo.Diffable, for: Any do
  def diff(a, b, path) do
    Rondo.Diffable.Map.diff(a, b, path)
  end
end
