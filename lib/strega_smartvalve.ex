defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Strega Smart Valve
  # According to documentation (v3.0) provided by Strega
  # Link: https://sensoneo.com/product/smart-sensors/
  #
  # Changelog
  #   2018-09-13 [as]: Initial version.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #


  def parse(<<bat_mv::binary-4, vt::binary-1, _rest::binary>>, _meta) do
    %{
      bat_v: String.to_integer(bat_mv)/1000,
      valvestatus: if(vt == "1" or vt == "3" , do: "open", else: "closed"),
      lidstatus: if(vt == "2" or vt == "3" , do: "open", else: "closed")
    }
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields do
    [
      %{
        field: "bat_v",
        display: "Battery voltage",
        unit: "V"
      },
      %{
        field: "valvestatus",
        display: "Valve status"
      },
      %{
        field: "lidstatus",
        display: "Lid status"
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "3330343830", %{}, %{
          valvestatus: "closed",
          lidstatus: "closed",
          bat_v: 3.048
        }
      },
      {
        :parse_hex, "3330313131", %{}, %{
          valvestatus: "open",
          lidstatus: "closed",
          bat_v: 3.011
        }
      },
      {
        :parse_hex, "3330333832", %{}, %{
          valvestatus: "closed",
          lidstatus: "open",
          bat_v: 3.038
        }
      },
      {
        :parse_hex, "3239323733", %{}, %{
          valvestatus: "open",
          lidstatus: "open",
          bat_v: 2.927
        }
      }
    ]
  end

end
