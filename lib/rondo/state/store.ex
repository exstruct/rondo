defprotocol Rondo.State.Store do
  def mount(store, descriptor)
  def handle_info(store, info)
  def handle_action(store, descriptor, update_fn)
  def encode(store)
  def decode_into(store, token)
end
