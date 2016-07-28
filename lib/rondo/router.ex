defmodule Rondo.Router do
  defstruct [:id, :init, :route]

  defmacro __using__(_) do
    quote do
      use Rondo.Component

      @router %Rondo.Router{
        id: __MODULE__,
        init: &__MODULE__.init/1,
        route: &__MODULE__.route/2
      }

      def store do
        Rondo.Router.store(@router)
      end

      def action(route, events \\ []) do
        action(store(), @router, route, events)
      end

      def event(route) do
        event(store(), @router, route)
      end

      # element callbacks
      def state(props, context) do
        Rondo.Element.Mountable.Rondo.Router.state(@router, props, context)
      end

      def context(state) do
        Rondo.Element.Mountable.Rondo.Router.context(@router, state)
      end

      def render(state) do
        Rondo.Element.Mountable.Rondo.Router.render(@router, state)
      end
    end
  end

  def store(%{id: component_path, init: init}, params \\ %{}, id \\ nil) do
    %Rondo.Store{
      component_path: component_path,
      state_path: [:route],
      type: Rondo.Router,
      props: init.(params),
      id: id
    }
  end

  def route(%{route: get_route}, params, route) do
    get_route.(params, route)
  end
end

defimpl Rondo.Element.Mountable, for: Rondo.Router do
  def state(router, params, _) do
    %{
      params: params,
      route: Rondo.Router.store(router, params)
    }
  end

  def context(_, _) do
    %{}
  end

  def render(router, %{params: params, route: route}) do
    Rondo.Router.route(router, params, route)
  end
end

defimpl Rondo.Action.Handler, for: Rondo.Router do
  def affordance(_, _) do
    %{}
  end

  def action(_, route, _, _) do
    route
  end
end

defimpl Rondo.Event.Handler, for: Rondo.Router do
  def event(_, route, _, _) do
    route
  end
end
