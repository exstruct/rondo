defprotocol Rondo.State.Store do
  def initialize(store)
  def mount(store, descriptor)
  def finalize(store)
  def handle_info(store, info)
  def handle_action(store, descriptor, update_fn)
  def encode(store)
  def decode_into(store, token)
end
