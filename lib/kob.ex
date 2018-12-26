defmodule Kob do
  @moduledoc """
  Documentation for Kob.
  """
  # import Plug

  @type handler :: (Plug.Conn.t() -> Plug.Conn.t())

  @type middleware :: (handler -> handler)

  @spec compose([middleware]) :: middleware
  def compose(mws) when is_list(mws) do
    fn next ->
      mws
      |> Enum.reverse()
      |> Enum.reduce(next, fn prev, next ->
        prev.(next)
      end)
    end
  end

  @type t :: %__MODULE__{
          mws: [middleware()]
        }

  defstruct mws: []

  @spec new() :: t
  def new() do
    %Kob{mws: []}
  end

  @spec use(t, middleware) :: t
  def use(%Kob{mws: mws}, mw) do
    %Kob{mws: [mw | mws]}
  end

  @spec handle(handler) :: middleware
  def handle(f) do
    fn _ -> f end
  end

  @spec through(handler) :: middleware
  def through(f) do
    fn next ->
      fn conn ->
        next.(f.(conn))
      end
    end
  end

  @spec switch((Plug.Conn.t() -> boolean), middleware) :: middleware
  def switch(condition, middleware) do
    fn next ->
      other = middleware.(next)

      fn conn ->
        if condition.(conn) do
          other.(conn)
        else
          next.(conn)
        end
      end
    end
  end

  @spec plug(Plug.Builder.plug(), Plug.opts()) :: middleware
  def plug(plug, opts \\ []) when is_atom(plug) do
    fn next ->
      x = apply(plug, :init, [opts])

      fn conn ->
        case apply(plug, :call, [conn, x]) do
          %{halted: true} = new_conn ->
            new_conn

          new_conn ->
            next.(new_conn)
        end
      end
    end
  end

  @spec to_middleware(t) :: middleware
  def to_middleware(%Kob{mws: mws}) do
    mws
    |> Enum.reverse()
    |> compose()
  end

  @spec to_handler(t) :: middleware
  def to_handler(%Kob{} = kob) do
    to_middleware(kob).(fn conn -> conn end)
  end

  @spec register_plug(t, Plug.Builder.plug()) :: :ok
  def register_plug(%Kob{} = kob, plug) when is_atom(plug) do
    :persistent_term.put(plug, to_handler(kob))

    Code.eval_string("
      defmodule #{plug} do
        def init(_opt) do
          :persistent_term.get(#{plug})
        end

        def call(conn, handler) do
          handler.(conn)
        end
      end
    ")

    :ok
  end
end
