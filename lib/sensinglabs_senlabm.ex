defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Sensing Labs "SenLab LED"
  #
  
  def parse(<<0x02, battery, rest::binary>>, _meta) do

    # Calculate how long the variable length is. We expect 4 bytes (32bit) behind the variable part.
    variable_length = byte_size(rest)-4

    # Use the size() modifier to match the variable part, match for any values behind the binary part.
    <<_variable::binary-size(variable_length), number::32>> = rest

    %{
      battery_percent: trunc((battery/254) * 100),
      number: number,
      kWh: number/1000+129.15,
    }
  end

  def tests() do
    [
      {
        :parse_hex, "021299887766", %{}, %{battery_percent: 7, number: 2575857510},
      },
      {
        :parse_hex, "02120099887766", %{}, %{battery_percent: 7, number: 2575857510},
      },
      {
        :parse_hex, "0212000099887766", %{}, %{battery_percent: 7, number: 2575857510},
      },
      {
        :parse_hex, "021200000099887766", %{}, %{battery_percent: 7, number: 2575857510},
      },
      {
        :parse_hex, "02120000000099887766", %{}, %{battery_percent: 7, number: 2575857510},
      },
    ]
  end
end
