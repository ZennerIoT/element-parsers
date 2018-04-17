defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Ascoel CM868LRTH sensor. Magnetic door/window sensor + temperature and humidity
  # According to documentation provided by Ascoel

  def parse(<<evt::8, count::16, temp::float-little-32, hum::float-little-32>>, %{meta: %{frame_port: 30 }}) do
    << res::3, ins::2, blow::1, tamper::1, intr::1>> = << evt::8 >>

    <<counter::integer>>=<<count::integer>>

    %{
      messagetype: "event",
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: counter,
      temperature: temp,
      humidity: hum
    }
  end

  def parse(<<bat_t::1, bat_p::7, evt::8, temp::float-little-32, hum::float-little-32>>, %{meta: %{frame_port: 9 }}) do
    << res::3, ins::2, blow::1, tamper::1, intr::1>> = << evt::8 >>

    %{
      messagetype: "status",
      battery: bat_p,
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      temperature: temp,
      humidity: hum
    }
  end

  def fields do
    [
      %{
        "field" => "counter",
        "display" => "Openings",
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "humidity",
        "display" => "Humidity",
        "unit" => "%"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "01000A61F2C341A0661542", %{? => %{"frame_port" => 30}}, %{
          messagetype: "event",
          intrusion: 1,
          tamper: 0,
          batterywarn: 0,
          counter: 10,
          temperature: "24.493349075317383",
          humidity: "37.3502197265625"
        }
      }
    ]
  end
end
