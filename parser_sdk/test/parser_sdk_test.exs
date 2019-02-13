defmodule ParserSdkTest do
  use ExUnit.Case
  doctest ParserSdk

  test "greets the world" do
    assert ParserSdk.hello() == :world
  end
end
