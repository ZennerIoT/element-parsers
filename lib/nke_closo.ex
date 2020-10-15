defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for NKE Watteco Clos'O
  #
  # Link: https://www.nke-watteco.com/product/closo-sensor-lorawan/
  # Documentation: http://support.nke-watteco.com/
  #
  # Changelog
  #   2020-10-15 [jb]: Initial implementation according to "Clos'O_50-70-108-000_SPG_V0_9 EN _1_.pdf".
  #

  def parse(<<
    0x11, #fctrl
    0x0A, # cmdid
    0x00, 0x50, # clusterid = configuration
    0x00, 0x06, # attributeid
    0x41,
    0x05, power_mode, _power_sources, voltage_level::16, power_source
  >>, _meta) do

    power_mode = case power_mode do
      0x00 -> :on_when_idle
      0x01 -> :periodically_on
      0x02 -> :on_on_user_event
      _ -> "unknown_#{power_mode}"
    end

    power_source = case power_source do
      0x00 -> :undefined
      0x01 -> :main_power
      0x02 -> :rechargeable_battery
      0x04 -> :disposeable_battery
      0x08 -> :solar
      0x10 -> :tic
      _ -> "unknown_#{power_source}"
    end

    %{
      power_mode: power_mode,
      power_source: power_source,
      power_voltage: voltage_level/1000,
    }
  end

  def parse(<<sensor, 0x0a, 0x00, 0x0f, 0x00, 0x55, 0x10, state>>, _meta) do
    event = case {sensor, state} do
      {0x11, 0x00} -> :sensor_housing_open
      {0x11, 0x01} -> :sensor_housing_closed
      {0x31, 0x00} -> :gate_open
      {0x31, 0x01} -> :gate_closed
    end
    %{event: event}
  end
  def parse(<<>>, _meta) do
    []
  end
  def parse(payload, meta) do
    Logger.info("UNKNOWN payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fields() do
    [
      %{
        field: "power_voltage",
        display: "Voltage",
        unit: "V",
      },
      %{
        field: "power_mode",
        display: "PowerMode",
      },
      %{
        field: "power_source",
        display: "PowerSource",
      },

      %{
        field: "event",
        display: "Event",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "110A00500006410501040E0604",
        %{
          _comment: "Node Power Descriptor attribute represents the power mode and supply characteristics of the device",
        },
        %{
          power_mode: :periodically_on,
          power_source: :disposeable_battery,
          power_voltage: 3.59
        }
      },

      {
        :parse_hex,
        "11 0a 00 0f 00 55 10 00",
        %{
          _comment: "Sensor housing torn off",
        },
        %{event: :sensor_housing_open}
      },

      {
        :parse_hex,
        "11 0a 00 0f 00 55 10 01",
        %{
          _comment: "Sensor housing in place",
        },
        %{event: :sensor_housing_closed}
      },

      {
        :parse_hex,
        "31 0a 00 0f 00 55 10 00",
        %{
          _comment: "Open portal",
        },
        %{event: :gate_open}
      },

      {
        :parse_hex,
        "31 0a 00 0f 00 55 10 01",
        %{
          _comment: "Closed gate",
        },
        %{event: :gate_closed}
      },
    ]
  end
end
