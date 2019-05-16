defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # !!! This Parser is not maintained anymore. Use tabs.ex instead !!!
  #
  # ELEMENT IoT Parser for TrackNet Tabs Motion Sensor
  # According to documentation provided by TrackNet
  # Payload Description Version v1.3
  #
  # Changelog
  #   2018-05-02 [as]: Initial version.
  #   2019-04-04 [jb]: Fixed invalid "temperature" value and typo. Added tests.
  #   2019-04-04 [gw]: Corrected name of device in comment.


  def parse(<<_stat_rfu::7, stat::1, bat_c::4, bat_v::4, _temp_rfu::1, temp::7, _time::little-16, count::little-24>>, %{meta: %{frame_port: 102}}) do
    %{
      sensor_status: stat,
      batterie_voltage: (25+bat_v)/10,
      batterie_capacity: 100*(bat_c/15),
      temperature: temp-32,
      count: count,
    }
  end
  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  def fields do
    [
      %{
        "field" => "battery_capacity",
        "display" => "Battery Capacity",
        "unit" => "%"
      },
      %{
        "field" => "battery_voltage",
        "display" => "Battery voltage",
        "unit" => "V"
      },
      %{
        "field" => "count",
        "display" => "Counter"
      },
      %{
        "field" => "temperature",
        "display" => "Temperature",
        "unit" => "°C"
      },
      %{
        "field" => "sensor_status",
        "display" => "Movement"
       }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "01FB060000CC0E00", %{meta: %{frame_port: 102}},
        %{
          batterie_capacity: 100.0,
          batterie_voltage: 3.6,
          count: 3788,
          sensor_status: 1,
          temperature: -26
        }
      },
      {
        :parse_hex, "00FB340500AB0D00", %{meta: %{frame_port: 102}},
        %{
          batterie_capacity: 100.0,
          batterie_voltage: 3.6,
          count: 3499,
          sensor_status: 0,
          temperature: 20
        }
      },
    ]
  end
end
