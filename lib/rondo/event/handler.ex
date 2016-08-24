defprotocol Rondo.Event.Handler do
  def event(handler, props, state, data)
end

defimpl Rondo.Event.Handler, for: Atom do
  def event(handler, props, state, data) do
    handler.event(props, state, data)
  end
end

defimpl Rondo.Event.Handler, for: Function do
  def event(handler, _props, state, _data) when is_function(handler, 0) do
    handler.()
    state
  end
  def event(handler, _props, state, _data) when is_function(handler, 1) do
    handler.(state)
  end
  def event(handler, _props, state, data) when is_function(handler, 2) do
    handler.(state, data)
  end
  def event(handler, props, state, data) when is_function(handler, 3) do
    handler.(props, state, data)
  end
end
