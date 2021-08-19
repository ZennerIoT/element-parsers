defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Example parser for variable length of payload
  #
  # Problem is a variable length of bytes in the middle of the payload that should be skipped.
  #
  # Changelog:
  #   2018-06-07 [jb]: Initial version for demonstrating purposes.
  #

  # Match for the first known bytes before the variable part, call the rest of the bytes "rest".
  def parse(<<0x02, battery, rest::binary>>, _meta) do
    # Calculate how long the variable length is. We expect 4 bytes (32bit) behind the variable part.
    variable_length = byte_size(rest) - 4

    # Use the size() modifier to match the variable part, match for any values behind the binary part.
    <<_variable::binary-size(variable_length), number::32>> = rest

    %{
      battery_percent: trunc(battery / 254 * 100),
      number: number
    }
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  def tests() do
    [
      {
        :parse_hex,
        "021299887766",
        %{},
        %{battery_percent: 7, number: 2_575_857_510}
      },
      {
        :parse_hex,
        "02120099887766",
        %{},
        %{battery_percent: 7, number: 2_575_857_510}
      },
      {
        :parse_hex,
        "0212000099887766",
        %{},
        %{battery_percent: 7, number: 2_575_857_510}
      },
      {
        :parse_hex,
        "021200000099887766",
        %{},
        %{battery_percent: 7, number: 2_575_857_510}
      },
      {
        :parse_hex,
        "02120000000099887766",
        %{},
        %{battery_percent: 7, number: 2_575_857_510}
      }
    ]
  end
end
