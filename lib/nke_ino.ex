defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for NKE Watteco IN'O
  #
  # Link: http://www.nke-watteco.com/product/ino-lora-state-report-and-output-control-sensor/
  # Documentation: http://support.nke-watteco.com/ino
  #
  # Features:
  # - Parses state from all 10 inputs.
  # - No support for counters yet.
  # - No support for cmdid, clusterid, attrid, attrtype from protocol.
  #
  # Changelog
  #   2018-09-17 [jb]: Handling missing fctrl, added fields like "input_2_state" for better historgrams.


  def parse(<<fctrl::8, _cmdid::8, _clusterid::16, 0x00, 0x55, _attrtyp::8, data::8>>, _meta) do

    input = case fctrl do
      0x11 -> 1
      0x31 -> 2
      0x51 -> 3
      0x71 -> 4
      0x91 -> 5
      0xB1 -> 6
      0xD1 -> 7
      0xF1 -> 8
      0x13 -> 9
      0x33 -> 10
      _ -> nil
    end

    case input do
      nil ->
        # No matching fctrl found, skip creating reading
        []
      input ->
        %{
          :input => input,
          :state => data,
          "input_#{input}_state" => data,# Adding a specific field for a input.
        }
    end
  end

  def parse(<<fctrl::8, _cmdid::8, _clusterid::16, 0x04, 0x02, _attrtyp::8, count::32>>, _meta) do

    input = case fctrl do
      0x11 -> 1
      0x31 -> 2
      0x51 -> 3
      0x71 -> 4
      0x91 -> 5
      0xB1 -> 6
      0xD1 -> 7
      0xF1 -> 8
      0x13 -> 9
      0x33 -> 10
      _ -> nil
    end

    case input do
      nil ->
        # No matching fctrl found, skip creating reading
        []
      input ->
        %{
          :input => input,
          :counter => count,
          "input_#{input}_state" => count,# Adding a specific field for a input.
        }
    end
  end

  def tests() do
    [
      {
        :parse_hex, "710A000F00551001", %{}, %{
          :input => 4,
          :state => 1,
          "input_4_state" => 1,
        }
      },
      {
        :parse_hex, "310A000F00551000", %{}, %{
          :input => 2,
          :state => 0,
          "input_2_state" => 0,
        }
      },
      {
        :parse_hex, "990A000F00551000", %{}, []
      },
    ]
  end
end
