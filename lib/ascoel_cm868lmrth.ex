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

  def parse(evt, _meta) do
    %{

    }
  end

end
