defprotocol Rondo.Event.Handler do
  def event(handler, props, state, data)
end

defimpl Rondo.Event.Handler, for: Atom do
  def event(handler, props, state, data) do
    handler.event(props, state, data)
  end
end
