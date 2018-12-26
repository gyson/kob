# Kob

Another way to compose "Plug"s.

## Rational

An experiment to seek another way (no macro?) for composing "Plug"s. The idea is based on my experience from [koajs](https://koajs.com/).

## Note

This package requires **OTP 21.2**, which was released on Dec 12, 2018.

## Installation

```elixir
def deps do
  [
    {:kob, "~> 0.1.1"},
  ]
end
```

Docs can be found at [https://hexdocs.pm/kob](https://hexdocs.pm/kob).

## Example

```elixir
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
```

## Compare Kob and Plug

It's encouraged to take a look with Kob's [source code](https://github.com/gyson/kob/blob/master/lib/kob.ex) to have better understanding of it. The core part is `Kob.compose` function, which is only a few lines of code.

The key design of Kob is two types:

- `@type handler :: (Plug.Conn.t() -> Plug.Conn.t())` : This is similar to Plug, which is the function to handle `Plug.Conn` transformation.

- `@type middleware :: (handler -> handler)` : This is how Kob does composistion. It chains things together.

This design has a few benefits:

- It enables `middleware` to determine if continue to next one. For example,

  ```elixir
  fn next ->
    fn conn ->
      if for_some_case do
        # we want to pass `conn` to next middleware
        next.(conn)
      else
        # we want to response and stop pipeline
        conn
        |> Plug.Conn.send_resp(200, "OK)
      end
    end
  end
  ```
  Plug can deal with this case via [`Plug.Conn.halt`](https://hexdocs.pm/plug/Plug.Conn.html#halt/1).

- It enables `middleware` to do something work afterwards. For example,
  ```elixir
    fn next ->
      fn conn ->
        # pass it to next middleware and wait for its returning
        conn = next.(conn)

        # downstream middlewares are finished now. We can do some cleanup now.
        # For example, we can log time, we can clear session, etc.
        do_some_work()

        # pass it back to previous middleware
        conn
      end
    end
  ```
  Plug can deal with similar case via [`Plug.Conn.before_send`](https://hexdocs.pm/plug/Plug.Conn.html#t:before_send/0).

- It enables upstream `middleware` to handle errors from downstream `middleware`. For example,
  ```elixir
  Kob.compose([
    # upstream middleware
    fn next ->
      fn conn ->
        try do
          next.(conn)
        rescue
          RuntimeError ->
            handle_error()
        after
          cleanup()
        end
      end
    end,

    # downstream middleware
    fn next ->
      fn conn ->
        raise "something error"
      end
    end
  ])
  ```
  Plug can deal with similar case via [`Plug.ErrorHandler`](https://hexdocs.pm/plug/Plug.ErrorHandler.html).

## Kob and Plug are interchangeable

- We can convert a Plug to Kob middleware via `Kob.plug/2`.
- We can convert a Kob struct/middleware to a Plug via `Kob.register_plug/1`.

## License

MIT
