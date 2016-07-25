defprotocol Rondo.Element.Mountable do
  def state(element, props, context)
  def context(element, state)
  def render(element, state)
end

defimpl Rondo.Element.Mountable, for: BitString do
  def state(_, props, _) do
    props
  end

  def context(_, _) do
    %{}
  end

  def render(element, props) do
    {children, props} = Map.pop(props, :children)
    %Rondo.Element{type: element, props: props, children: children || []}
  end
end

defimpl Rondo.Element.Mountable, for: Atom do
  def state(mod, props, context) do
    mod.state(props, context)
  end

  def context(mod, state) do
    mod.context(state)
  end

  def render(mod, state) do
    mod.render(state)
  end
end
