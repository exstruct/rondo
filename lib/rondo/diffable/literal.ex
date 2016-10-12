defimpl Rondo.Diffable, for: [Atom, BitString, Integer, Float] do
  import Rondo.Operation

  def diff(current, current, _) do
    []
  end
  def diff(current, _, path) do
    [replace(path, current)]
  end
end
