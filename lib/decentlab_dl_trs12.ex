defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # original source: https://github.com/decentlab/decentlab-decoders/blob/master/DL-TRS12/DL-TRS12.ELEMENT-IoT.ex
  #
  # ELEMENT IoT Parser for Decentlab DL-TRS12:
  # SOIL MOISTURE, TEMPERATURE AND ELECTRICAL CONDUCTIVITY SENSOR FOR LoRaWAN
  # Further info at: https://www.decentlab.com/products/soil-moisture-temperature-and-electrical-conductivity-sensor-for-lorawan
  #
  # Changelog
  #   2019-07-10 [ab]: Initial version. Code cleanup. Tests.

  def fields do
    [
      %{"field" => "dielectric_permittivity", "display" => "Dielectric permittivity", "unit" => "None"},
      %{"field" => "volumetric_water_content", "display" => "Volumetric water content", "unit" => "m³⋅m⁻³"},
      %{"field" => "soil_temperature", "display" => "Soil temperature", "unit" => "°C"},
      %{"field" => "electrical_conductivity", "display" => "Electrical conductivity", "unit" => "µS⋅cm⁻¹"},
      %{"field" => "battery_voltage", "display" => "Battery voltage", "unit" => "V"}
    ]
  end

  def parse(<<
      2,
      device_id::16,
      flags::bytes-2,
      words::bytes
    >>, _meta) do
    {_remaining, result} =
      {words, %{:device_id => device_id, :protocol_version => 2}}
      |> parse_sensor_data(flags)
      |> parse_battery_voltage(flags)

    result
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_sensor_data({<<
      vwc_raw::16,
      soil_temp::16,
      e_conduct::16,
      remaining::bytes
    >>, result},
    <<
      _::15,
      1::1,
#      _::0
    >>) do
    vwc_raw_conv = vwc_raw/10
    {remaining, Map.merge(result,
        %{
          :dielectric_permittivity =>
            :math.pow(
              0.000000002887 * :math.pow(vwc_raw_conv, 3) -
              0.0000208 * :math.pow(vwc_raw_conv, 2) +
              0.05276 * (vwc_raw_conv) - 43.39,
              2)
            |> round_as_float(),
          :volumetric_water_content => (vwc_raw_conv * 0.0003879 - 0.6956)
                                       |> round_as_float(),
          :soil_temperature => (soil_temp - 32768) / 10,
          :electrical_conductivity => e_conduct
        })}
  end
  defp parse_sensor_data(result, _flags), do: result

  defp parse_battery_voltage(
         {<<
           battery_voltage::16,
           remaining::bytes
         >>, result},
         <<
           _::14,
           1::1,
           _::1
         >>) do
    {remaining,
      Map.merge(result,
        %{
          :battery_voltage => battery_voltage / 1000
        })}
  end
  defp parse_battery_voltage(result, _flags), do: result

  defp round_as_float(value) do
    Float.round(value / 1, 4)
  end

  def tests() do
    [
      {
        :parse_hex,
        String.replace("02 10d3 0002 0c80", " ", ""),
        %{},
        %{
          :protocol_version => 2,
          :device_id => 4307,
          :battery_voltage => 3.2
        }
      },
      {
        :parse_hex,
        String.replace("02 10d3 0003 46be 813d 0000 0c80", " ", ""),
        %{},
        %{
          :protocol_version => 2,
          :device_id => 4307,
          :battery_voltage => 3.2,
          :dielectric_permittivity => 1.1831,
          :volumetric_water_content => 0.0069,
          :soil_temperature => 31.7,
          :electrical_conductivity => 0
        }
      }
    ]

  end

end