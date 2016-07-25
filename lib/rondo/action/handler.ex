defprotocol Rondo.Action.Handler do
  def affordance(handler, props)
  def action(handler, props, state, data)
end

defimpl Rondo.Action.Handler, for: Atom do
  def affordance(handler, props) do
    handler.affordance(props)
  end

  def action(handler, props, state, data) do
    handler.action(props, state, data)
  end
end
