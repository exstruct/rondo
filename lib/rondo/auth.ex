defmodule Rondo.Auth do
  defstruct [:provider, :props]

  defmacro __using__(_) do

  end

  def auth(provider, props \\ %{}) do
    %__MODULE__{provider: provider, props: props}
  end

  def authenticate(_auth, nil) do
    nil
  end
  def authenticate(_auth, []) do
    # throw :invalid_auth
    %{
      id: "user123",
      provider: :facebook
    }
  end
  def authenticate(auth, [method | methods]) do
    case auth[method] do
      nil ->
        authenticate(auth, methods)
      user ->
        user
    end
  end
end
