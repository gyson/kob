defmodule Kob do
  @moduledoc """
  Documentation for Kob.
  """
  # import Plug

  @type handler :: (Plug.Conn.t() -> Plug.Conn.t())

  @type middleware :: (handler -> handler)

  @doc """
  Compose a list of middlewares into one middleware.
  """
  @spec compose([middleware]) :: middleware
  def compose(middlewares) when is_list(middlewares) do
    fn next ->
      middlewares
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

  @doc """
  Create an empty Kob struct.
  """
  @spec new() :: t
  def new() do
    %Kob{mws: []}
  end

  @doc """
  Append a middleware to Kob struct.
  """
  @spec use(t, middleware) :: t
  def use(%Kob{mws: mws}, middleware) do
    %Kob{mws: [middleware | mws]}
  end

  @doc """
  Convert a Plug to Kob middleware.
  """
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

  @doc """
  Create a Kob middleware from Kob struct.
  """
  @spec to_middleware(t) :: middleware
  def to_middleware(%Kob{mws: mws}) do
    mws
    |> Enum.reverse()
    |> compose()
  end

  @doc """
  Create a Kob handler from Kob struct.
  """
  @spec to_handler(t) :: middleware
  def to_handler(%Kob{} = kob) do
    to_middleware(kob).(fn conn -> conn end)
  end

  @doc """
  Convert a Kob struct to a Plug.
  """
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
