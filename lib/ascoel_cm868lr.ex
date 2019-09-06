defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #

  def parse(<<evt::8, count::16>>, %{meta: %{frame_port: 30 }}) do
    << _res::3, _ins::2, blow::1, tamper::1, intr::1 >> = <<evt::8>>

    %{
      messagetype: "event",
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: count
    }
  end

  def parse(<< _bat_t::1, bat_p::7, evt::8, count::16>>, %{meta: %{frame_port: 9 }}) do
    << _res::3, _ins::2, blow::1, tamper::1, intr::1>> = <<evt::8>>

    %{
      messagetype: "status",
      battery: bat_p,
      intrusion: intr,
      tamper: tamper,
      batterywarn: blow,
      counter: count
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
        "display" => "Openings",
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "020001", %{meta: %{frame_port: 30}}, %{
          messagetype: "event",
          intrusion: 0,
          tamper: 1,
          batterywarn: 0,
          counter: 1
        }
      },
      {
        :parse_hex, "E4000016", %{meta: %{frame_port: 9}}, %{
          messagetype: "status",
          intrusion: 0,
          tamper: 0,
          battery: 100,
          batterywarn: 0,
          counter: 22
        }
      }
    ]
  end

end
