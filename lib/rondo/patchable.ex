defprotocol Rondo.Patchable do
  @fallback_to_any true
  def patch(value, doc)
end

defimpl Rondo.Patchable, for: Any do
  def patch(value, doc) do
    Rondo.Patchable.Map.patch(value, doc)
  end
end
