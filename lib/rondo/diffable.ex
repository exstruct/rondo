defprotocol Rondo.Diffable do
  def diff(current, prev, path)
end
