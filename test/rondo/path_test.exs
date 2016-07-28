defmodule Test.Rondo.Path do
  use Test.Rondo.Case
  import Rondo.Path

  property :round_trip do
    for_all paths in such_that(l in list(list(pos_integer)) when length(l) > 0)  do
      path = from_list(paths)

      # check that we can inspect while we're here
      inspect(path)

      (paths == to_list(path)) || {paths, path, to_list(path)}
    end
  end
end
