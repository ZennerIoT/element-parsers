defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Ascoel IT868LR sensor. Pyroelectric Motion Detector
  # According to documentation provided by Ascoel

  def parse(<<evt::8, count::unsigned-16>>, %{meta: %{frame_port: 20 }}) do
    << res::5, blow::1, tamper::1, intr::1>> = <<evt::8>>

    <<counter::integer>>=<<count::integer>>

    %{
      messagetype: "event",
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: counter
    }
  end

  def parse(<<bat_t::1, bat_p::7, evt::8, counter::unsigned-16>>, %{meta: %{frame_port: 9 }}) do
    << res::5, blow::1, tamper::1, intr::1>> = <<evt::8>>

    %{
      messagetype: "status",
      battery: bat_p,
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: counter
    }
  end

  def parse(evt, _meta) do
    %{

    }
  end

end
