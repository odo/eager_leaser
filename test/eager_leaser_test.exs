defmodule EagerLeaserTest do
  use ExUnit.Case
  doctest EagerLeaser

  test "greets the world" do
    assert EagerLeaser.hello() == :world
  end
end
