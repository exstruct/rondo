defmodule Rondo do
  alias Rondo.Application

  def create_application(element) do
    Application.init(element)
  end
end
