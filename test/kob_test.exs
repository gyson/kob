defmodule KobTest do
  use ExUnit.Case
  doctest Kob

  test "Kob.compose" do
    middleware =
      Kob.compose([
        fn next ->
          fn conn ->
            conn = [1 | conn]
            conn = next.(conn)
            conn = [7 | conn]
          end
        end,
        fn next ->
          fn conn ->
            conn = [2 | conn]
            conn = next.(conn)
            conn = [6 | conn]
          end
        end,
        fn next ->
          fn conn ->
            conn = [3 | conn]
            conn = next.(conn)
            conn = [5 | conn]
          end
        end
      ])

    handler =
      middleware.(fn conn ->
        [4 | conn]
      end)

    assert handler.([]) == [7, 6, 5, 4, 3, 2, 1]
  end
end
