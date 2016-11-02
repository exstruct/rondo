defmodule Rondo.Router do
  defstruct [:id, :init, :route, :state, :context, :render]

  defmacro __using__(_) do
    quote do
      use Rondo.Component

      @router %Rondo.Router{
        id: __MODULE__,
        init: &__MODULE__.init/1,
        route: &__MODULE__.route/2,
        state: &__MODULE__.state/2,
        context: &__MODULE__.context/1,
        render: &__MODULE__.render/1
      }

      def __router__ do
        @router
      end

      def store do
        Rondo.Router.store(@router)
      end

      def action(route, events \\ []) do
        action(store(), @router, route, events)
      end

      def event(route) do
        event(store(), @router, route)
      end

      def render(state) do
        Rondo.Router.render(@router, state)
      end

      defoverridable [render: 1]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defoverridable [state: 2]

      def state(props, context) do
        props
        |> super(context)
        |> Map.merge(Rondo.Router.state(@router, props, context))
      end
    end
  end

  def store(%{id: component_path}) do
    %Rondo.Store.Instance{
      component_path: component_path,
      state_path: [:route],
      type: :ephemeral,
      props: nil
    }
  end

  def state(%{} = router, _, _) do
    %{
      route: store(router)
    }
  end

  def render(%{init: init} = router, %{route: nil} = state) do
    case init.(state) do
      nil ->
        nil
      route ->
        render(router, %{state | route: route})
    end
  end
  def render(%{route: get_route}, %{route: route} = state) do
    get_route.(state, route)
  end
end

defimpl Rondo.Element.Mountable, for: Rondo.Router do
  def state(%{state: state}, params, context) do
    state.(params, context)
  end

  def context(%{context: context}, state) do
    context.(state)
  end

  def render(%{render: render}, state) do
    render.(state)
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
