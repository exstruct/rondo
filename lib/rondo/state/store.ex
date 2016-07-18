defprotocol Rondo.State.Store do
  def mount(store, component_path, state_path, descriptor)
  def handle_info(store, info)
  def handle_action(store, component_path, state_path, descriptor, update_fn)
  def encode(store)
  def decode_into(store, token)
end
