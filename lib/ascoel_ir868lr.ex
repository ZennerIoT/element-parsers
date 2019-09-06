defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Ascoel IT868LR sensor. Pyroelectric Motion Detector
  # According to documentation provided by Ascoel
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<evt::8, count::unsigned-16>>, %{meta: %{frame_port: 20 }}) do
    << _res::5, blow::1, tamper::1, intr::1>> = <<evt::8>>

    <<counter::integer>>=<<count::integer>>

    %{
      messagetype: "event",
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: counter
    }
  end

  def parse(<<_bat_t::1, bat_p::7, evt::8, counter::unsigned-16>>, %{meta: %{frame_port: 9 }}) do
    << _res::5, blow::1, tamper::1, intr::1>> = <<evt::8>>

    %{
      messagetype: "status",
      battery: bat_p,
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: counter
    }
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields do
    [
      %{
        "field" => "counter",
        "display" => "Movements"
      }
    ]
  end
end
