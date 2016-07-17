defprotocol Rondo.Manager do
  def create(creator, component_path, state_path, descriptor)
end
