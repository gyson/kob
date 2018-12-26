defmodule Kob.Example.Demo do
  def run() do
    Kob.new()
    |> Kob.use(fn next ->
      fn conn ->
        IO.puts("start middleware 1")
        conn = next.(conn)
        IO.puts("finish middleware 1")
        conn
      end
    end)
    |> Kob.use(fn next ->
      fn conn ->
        IO.puts("start middleware 2")
        conn = next.(conn)
        IO.puts("finish middleware 2")
        conn
      end
    end)
    |> Kob.use(Kob.plug(Plug.Logger, log: :debug))
    |> Kob.use(fn _ ->
      fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(200, "Hello world")
      end
    end)
    |> Kob.register_plug(MyKobPlug)

    {:ok, _} = Plug.Cowboy.http(MyKobPlug, [])
  end
end
