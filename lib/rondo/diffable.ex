defprotocol Rondo.Diffable do
  @fallback_to_any true
  def diff(current, prev, path)
end

defimpl Rondo.Diffable, for: Any do
  def diff(a, b, path) do
    Rondo.Diffable.Map.diff(a, b, path)
  end
end
