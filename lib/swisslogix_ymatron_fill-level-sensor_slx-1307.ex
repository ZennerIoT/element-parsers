defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Swisslogix/YMATRON SLX-1307 Parser
  #
  # The device is capable of measuring the ullage/filling level in a container.
  #
  # Example Commands:
  #   "!I:0060" - Set interval to 60 Minutes. Allowed are values between 1 and 720 minutes
  #   "!W:" - Activate WakeOnRadio feature for 24 hours.
  #
  # Changelog
  #   2019-03-28: [jb] Initial version of parser, according to DOC_1074_01_A_InterfaceLoRaFillLevelSensorSLX_1307_V1_1.pdf
  #

  # Readings
  # The reading telegram transmits the most recent reading of the sensor in millimetres. The sensor sends one reading telegram after each measurement.
  def parse(<<"C0:", data::binary>>, _meta) do
    with {:ok, distance_mm} <- parse_int(data) do
      %{distance: distance_mm, type: :reading}
    end
  end

  # Uplink Port 3 is not documented, so we do not use it for parsing.

  # Inquiries
  # Inquiry telegrams are used to gather more information about the sensor. A total of 6 inquiries are implemented
  # Note: The Battery Status inquiry is automatically executed once every 24h. The result is sent immediately following a reading telegram.
  # Note: After a reset the sensor sends an identification automatic sequence of S, D, T, and V inquiries. After every 500 th reading telegram one of the inquiries is automatically sent.
  def parse(<<"?B:", data::binary>>, _meta) do
    with {:ok, battery_mv} <- parse_int(data) do
      %{battery_voltage: battery_mv/1000, type: :inquiry}
    end
  end
  def parse(<<"?D:", device_type::binary>>, _meta) do
    %{device_type: device_type, type: :inquiry}
  end
  def parse(<<"?I:", data::binary>>, _meta) do
    with {:ok, interval_minutes} <- parse_int(data) do
      %{interval_minutes: interval_minutes, type: :inquiry}
    end
  end
  def parse(<<"?S:", serial_number::binary>>, _meta) do
    %{serial_number: serial_number, type: :inquiry}
  end
  def parse(<<"?T:", firmware::binary>>, _meta) do
    %{firmware_type: firmware, type: :inquiry}
  end
  def parse(<<"?V:", firmware::binary>>, _meta) do
    %{firmware_version: firmware, type: :inquiry}
  end

  # Catchall for reparsing
  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} on frame-port: #{inspect get(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_int(string) do
    string
    |> Kernel.to_string()
    |> String.trim_leading("0")
    |> Integer.parse()
    |> case do
         {value, ""} ->
           {:ok, value}
         error ->
           Logger.warn("Could not parse_int(#{inspect string}), got result: #{inspect error}")
           []
       end
  end

  def fields do
    [
      %{
        "field" => "type",
        "display" => "Typ",
      },
      %{
        "field" => "distance",
        "unit" => "mm",
        "display" => "Distanz",
      },
      %{
        "field" => "battery_voltage",
        "unit" => "V",
        "display" => "Batterie",
      },
      %{
        "field" => "interval_minutes",
        "unit" => "min",
        "display" => "Interval",
      },
      %{
        "field" => "serial_number",
        "display" => "Seriennummer",
      },
      %{
        "field" => "firmware_type",
        "display" => "Firmware-Typ",
      },
      %{
        "field" => "firmware_version",
        "display" => "Firmware-Version",
      },
    ]
  end

  def tests() do
    [
      # Readings
      {:parse_hex, "43303A31383237", %{meta: %{frame_port: 3}}, %{distance: 1827, type: :reading}},
      {:parse_hex, "43303A30333030", %{meta: %{frame_port: 3}}, %{distance: 300, type: :reading}},
      {:parse_hex, "43303A31383439", %{meta: %{frame_port: 3}}, %{distance: 1849, type: :reading}},

      # Inquiries
      {:parse_hex, "3F423A33363430", %{meta: %{frame_port: 3}}, %{battery_voltage: 3.64, type: :inquiry}},
      {:parse_hex, "3F443A3030303233", %{meta: %{frame_port: 3}}, %{device_type: "00023", type: :inquiry}},
      {:parse_hex, Base.encode16("?I:0030"), %{meta: %{frame_port: 3}}, %{interval_minutes: 30, type: :inquiry}}, # TODO: Get real interval inquiry (3F49...)
      {:parse_hex, "3F533A3030313037303834", %{meta: %{frame_port: 3}}, %{serial_number: "00107084", type: :inquiry}},
      {:parse_hex, "3F543A4657522D313031302D3035", %{meta: %{frame_port: 3}}, %{firmware_type: "FWR-1010-05", type: :inquiry}},
      {:parse_hex, "3F563A5630312E30312E3030", %{meta: %{frame_port: 3}}, %{firmware_version: "V01.01.00", type: :inquiry}},

      # Errorhandling
      {:parse_hex, Base.encode16("?B:ABCD"), %{meta: %{frame_port: 3}}, []},
      {:parse_hex, "1337", %{meta: %{frame_port: 3}}, []},
    ]
  end

end
