# rondo [![Build Status](https://travis-ci.org/exstruct/rondo.svg?branch=master)](https://travis-ci.org/exstruct/rondo) [![Hex.pm](https://img.shields.io/hexpm/v/rondo.svg?style=flat-square)](https://hex.pm/packages/rondo) [![Hex.pm](https://img.shields.io/hexpm/dt/rondo.svg?style=flat-square)](https://hex.pm/packages/rondo)

component rendering library

## Installation

`Rondo` is [available in Hex](https://hex.pm/docs/publish) and can be installed as:

  1. Add rondo your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:rondo, "~> 0.1.0"}]
end
```

## Usage

Start by creating a store

```elixir
defmodule MyApp.Store do
  defstruct [stores: %{}]

  defimpl Rondo.State.Store do
    def mount(%{stores: stores} = store, %{props: initial, type: :ephemeral} = descriptor) do
      stores = Map.put_new(stores, descriptor, initial)
      {Map.get(stores, descriptor), %{store | stores: stores}}
    end

    def handle_info(store, _info) do
      store
    end

    def handle_action(store, descriptor, update_fn) do
      {prev, store} = mount(store, descriptor)
      value = update_fn.(prev)
      stores = Map.put(store.stores, descriptor, value)
      {:ok, %{store | stores: stores}}
    end

    def encode(%{stores: stores}) do
      stores
      |> :erlang.term_to_binary()
      |> Base.url_encode64()
    end

    def decode_into(store, bin) do
      stores = bin
      |> Base.url_decode64!()
      |> :erlang.binary_to_term()
      %{store | stores: stores}
    end
  end
end
```

Now define an action with an affordance (jsonschema)

```
defmodule MyApp.Action.Increment do
  def affordance(_props) do
    %{
      "type" => ["integer", "null"]
    }
  end

  def action(_props, state, input) do
    state + (input || 0)
  end
end
```

And a component to use the action

```elixir
defmodule MyApp.Component do
  use Rondo.Component
  alias MyApp.Action.Increment

  def state(_props, _context) do
    %{
      counter: create_store(0)
    }
  end

  def render(%{counter: counter}) do
    el("Text", %{
      "increment" => ref([:counter]) |> action(Increment)
    }, [
      counter
    ])
  end
end
```

We can now render the app

```elixir
# Set up our store and app
store = %MyApp.Store{}
app = Rondo.create_application(MyApp.Component)

# Perform the initial render
{app, store} = Rondo.Application.render(app, store)

# Assert that the counter is initialized and being sent as the first child
{:ok, 0} = Rondo.Test.fetch_path(app, [0])

# We need to get the action ref to submit a form
{:ok, %{props: %{"increment" => %{ref: action_ref}}}} =
  Rondo.Test.fetch_path(app, [])

# If we submit an invalid action it should let us know
{:invalid, errors, app, store} =
  Rondo.submit_action(app, store, action_ref, "Invalid type")

# We now submit a valid action and it goes through
{:ok, app, store} =
  Rondo.submit_action(app, store, action_ref, 1)

# Trigger a render
{app, store} = Rondo.Application.render(app, store)

# We now have the incremented value!
{:ok, 1} = Rondo.Test.fetch_path(app, [0])
```
