defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for Adeunis Temperature Sensor ARF8180BA FW v2.0
  # According to documentation provided by Adeunis
  # Link: https://www.adeunis.com/en/produit/temp/
  # Documentation: https://www.adeunis.com/wp-content/uploads/2017/08/TEMP_LoRaWAN_UG_V2.0.0_FR_EN.pdf
  # Test hex payload: "43A2D1015E82FF06"
  # Only parse "data frames" when first byte is "0x43"

  def parse(<<67, status::8, internal_identifier::8, internal_value::signed-16, external_identifier::8, external_value::signed-16>>, _meta) do
  << internal_register::4, internal_status::4 >> = << internal_identifier::8 >>
  << external_register::4, external_status::4 >> = << external_identifier::8 >>

    internal_sensor = case internal_status do
      0 -> "error"
      1 -> "B57863S0303F040"
      _ -> "unknown"
    end
    external_sensor = case external_status do
      0 -> "error"
      1 -> "E-NTC-APP-1.5P7"
      2 -> "FANB57863-400-1"
      _ -> "unknown"
    end

    %{
      internal_sensor: internal_sensor,
      internal_temp: internal_value/10,
      external_sensor: external_sensor,
      external_temp: external_value/10,
    }
  end

end
