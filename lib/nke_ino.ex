defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for NKE Watteco IN'O
  # No general parser, only for "4-input/present value" configuration
  # Link: http://www.nke-watteco.com/product/ino-lora-state-report-and-output-control-sensor/
  # Documentation: http://support.nke-watteco.com/ino

  def parse(<<fctrl::8, _cmdid::8, _clusterid::16, _attrid::16, _attrtyp::8, data::8>>, _meta) do

    input = case fctrl do
      0x11 -> 1
      0x31 -> 2
      0x51 -> 3
      0x71 -> 4
    end

    %{
      input: input,
      state: data
    }
  end


  def tests() do
    [
      {
        :parse_hex, "710A000F00551001", %{}, %{
          input: 4,
          state: 1
        }
      },
      {
        :parse_hex, "310A000F00551000", %{}, %{
          input: 2,
          state: 0
        }
      }
    ]
  end
end
