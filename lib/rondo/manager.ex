defprotocol Rondo.Manager do
  def mount(manager, component_path, state_path, descriptor)
  def unmount(manager, component_path, state_path, descriptor)
  def handle_info(manager, info)
  def encode(manager)
  def decode_into(manager, key)
end
