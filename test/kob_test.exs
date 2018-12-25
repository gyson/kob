defmodule KobTest do
  use ExUnit.Case
  doctest Kob

  test "greets the world" do
    assert Kob.hello() == :world
  end
end
