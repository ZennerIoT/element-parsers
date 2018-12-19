defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for the DZG Plugin and Bridge using the v2.0 LoRaWAN Frame Format from file "LoRaWAN Frame Format 2.0.pdf".
  #
  # Changelog
  #   2018-11-28 [jb]: Reimplementation according to PDF.
  #   2018-12-03 [jb]: Handling MeterReading messages with missing frame header.
  #   2018-12-19 [jb]: Handling MeterReading messages with header v2. Fixed little encoding for some fields.

  # Structure of payload deciffered from PDF:
  #
  # Payload
  #   FrameHeader
  #     version::2 == 0
  #     isEncrypted::1 == 0
  #     hasMac::1 == 0
  #     isCompressed::1 == 0
  #     type::3
  #   counter::32 # if isEncrypted
  #   frame::binary
  #
  # HINT: Values are little-endian!

  # Parsing the payload header with expected flags:
  # version = 0
  # isEncrypted = 0
  # hasMac = 0
  # isCompressed = 0
  def parse(<<0::2, 0::1, 0::1, 0::1, type::3, frame::binary>>, _meta) do
    case type do
      0 -> # MeterReadingMessageEncrypted
        parse_meter_reading_message(frame)
      1 -> # StatusMessage
        parse_status_message(frame)
      _ -> # Ignored: FrameTypeRawSerial and FrameTypeIec1107
        Logger.info("Unhandled frame type: #{inspect type}")
        []
    end
  end

  # Handling MeterReading messages without Header.
  def parse(<<frame::binary>>, %{meta: %{frame_port: 8}}) do
    parse_meter_reading_message(frame)
  end

  # Error handler
  def parse(payload, meta) do
    Logger.info("Can not parse frame with payload: #{inspect Base.encode16(payload)} on frame port: #{inspect get(meta, [:meta, :frame_port])}")
    []
  end


  # Parsing the frame data for a meter reading.
  #
  #   MeterReadingData
  #     MeterReadingMessageHeader
  #       UNION
  #         MeterReadingMessageHeaderVersion1
  #           version::2 == 1
  #           medium::3
  #           qualifier::3
  #         MeterReadingMessageHeaderVersion2
  #           version::2 == 2
  #           hasTimestamp::1
  #           isCompressed::1
  #           medium_extended::4
  #           qualifier::8
  #     meterId::32
  #     SEQUENCE
  #       MeterReadingDataTuple
  #         timestamp::32 # when hasTimestamp=1
  #         SEQUENCE
  #           RegisterValue::32
  #
  # Matching hard on medium 2=electricity_kwh here, to avoid problems with headerv2
  def parse_meter_reading_message(<<1::2, 2::3, qualifier::3, meter_id::32-little, register_value::32-little>>) do
    medium = 2
    %{
      type: "meter_reading",
      header_version: 1,
      medium: medium_name(medium),
      qualifier: medium_qualifier_name(medium, qualifier),
      meter_id: meter_id,
      register_value: register_value / 100,
    }
  end

  # Supporting MeterReadingMessageHeaderVersion2 with 2 byte length
  # Problem: the 2 byte header is little endian, so the verson flag is at a DIFFERENT position than in MeterReadingMessageHeaderVersion1.
  def parse_meter_reading_message(<<qualifier::8, 2::2, has_timestamp::1, is_compressed::1, medium::4, rest::binary>>) do
    case {{medium, qualifier, has_timestamp, is_compressed}, rest} do
      {{2, 4, 1, 0}, <<meter_id::32-little, timestamp::32-little, register_value::32-little, register2_value::32-little>>} ->
        %{
          type: "meter_reading",
          header_version: 2,
          medium: medium_name_extended(medium),
          qualifier: medium_qualifier_name_extended(medium, qualifier),
          meter_id: meter_id,
          register_value: register_value / 100,
          register2_value: register2_value / 100,
          timestamp_unix: timestamp, # From device, can be wrong if device clock is wrong
          timestamp: DateTime.from_unix!(timestamp),
        }
      {header, binary} ->
        Logger.info("No creating meter reading because not matching header #{inspect header} and reading_data #{Base.encode16 binary}")
        []
    end

  end

  def parse_meter_reading_message(_) do
    Logger.info("Unknown MeterReadingData format")
    []
  end

  # Parsing the frame data for a status.
  #
  #   StatusData
  #     StatusDataFirstByte
  #       resetReason::3
  #       nodeType::2
  #       sessionInfo::3
  #     firmwareId::32
  #     uptime::32 # milliseconds
  #     time::32 # seconds, linux timestamp
  #     lastdownlinkPacked::32 # milliseconds
  #     DownlinkPacketInfo
  #       rssi::16
  #       snr::8
  #       frameType::8  # This was WRONG in PDF
  #       isAck::8   # This was WRONG in PDF
  #     numberOfConnectedDevices::8
  #
  def parse_status_message(<<reset_reason::3, node_type::2, session_info::3, firmware_id::binary-4, uptime_ms::32-little, time_s::32-little, last_downlink_ms::32-little, rssi::16-little, snr::8, frame_type::8, is_ack::8, connected_devices::8>>) do
    %{
      type: "status",
      reset_reason: reset_reason_name(reset_reason),
      node_type: node_type_name(node_type),
      session_info: session_info_name(session_info),
      firmware_id: Base.encode16(firmware_id),
      uptime_ms: uptime_ms,
      last_downlink_ms: last_downlink_ms,
      time_s: time_s,
      rssi: rssi,
      snr: snr,
      frame_type: frame_type,
      is_ack: is_ack,
      connected_devices: connected_devices,
    }
  end
  def parse_status_message(_) do
    Logger.warn("Unknown StatusData format")
    []
  end



  defp medium_qualifier_name(_, 0), do: "none"

  defp medium_qualifier_name(1, 1), do: "degreeCelsius"

  defp medium_qualifier_name(2, 1), do: "a-plus"
  defp medium_qualifier_name(2, 2), do: "a-plus-t1-t2"
  defp medium_qualifier_name(2, 4), do: "a-plus-a-minus"
  defp medium_qualifier_name(2, 5), do: "a-minus"
  defp medium_qualifier_name(2, 6), do: "a-plus-t1-t2-a-minus"

  defp medium_qualifier_name(3, 1), do: "volume"

  defp medium_qualifier_name(4, 1), do: "energy"

  defp medium_qualifier_name(6, 1), do: "tbd"

  defp medium_qualifier_name(7, 1), do: "volume"

  defp medium_qualifier_name(8, 1), do: "tbd"

  defp medium_qualifier_name(_, _), do: "unknown"

  defp medium_name(1), do: "temperature_celsius"
  defp medium_name(2), do: "electricity_kwh"
  defp medium_name(3), do: "gas_m3"
  defp medium_name(4), do: "heat_kwh"
  defp medium_name(6), do: "hotwater_m3"
  defp medium_name(7), do: "water_m3"
  defp medium_name(8), do: "heatcostallocator"
  defp medium_name(_), do: "unknown"

  defp session_info_name(0), do: "abp"
  defp session_info_name(1), do: "joined"
  defp session_info_name(2), do: "joinedLinkCheckFailed"
  defp session_info_name(3), do: "joinedLinkPeriodicRejoin"
  defp session_info_name(4), do: "joinedSessionResumed"
  defp session_info_name(5), do: "joinedSessionResumedJoinFailed"
  defp session_info_name(_), do: "unknown"

  defp node_type_name(0), do: "loramod"
  defp node_type_name(1), do: "brige"
  defp node_type_name(_), do: "unknown"

  defp reset_reason_name(0), do: "general"
  defp reset_reason_name(1), do: "backup"
  defp reset_reason_name(2), do: "wdt"
  defp reset_reason_name(3), do: "soft"
  defp reset_reason_name(4), do: "user"
  defp reset_reason_name(7), do: "slclk"
  defp reset_reason_name(_), do: "unknown"


  # Needed for MeterReadingMessageHeaderVersion2

  defp medium_name_extended(1), do: "temperature_celsius"
  defp medium_name_extended(2), do: "electricity_kwh"
  defp medium_name_extended(3), do: "gas_m3"
  defp medium_name_extended(4), do: "heat_kwh"
  defp medium_name_extended(6), do: "hotwater_m3"
  defp medium_name_extended(7), do: "water_m3"
  defp medium_name_extended(_), do: "unknown"

  defp medium_qualifier_name_extended(_, 0), do: "none"
  defp medium_qualifier_name_extended(2, 1), do: "a-plus"
  defp medium_qualifier_name_extended(2, 2), do: "a-plus-t1-t2"
  defp medium_qualifier_name_extended(2, 4), do: "a-plus-a-minus"
  defp medium_qualifier_name_extended(2, 5), do: "a-minus"
  defp medium_qualifier_name_extended(2, 6), do: "a-plus-t1-t2-a-minus"
  defp medium_qualifier_name_extended(2, 7), do: "a-plus-a-minus-r1-r2-r3-r4"
  defp medium_qualifier_name_extended(2, 8), do: "loadprofile"
  defp medium_qualifier_name_extended(_, _), do: "unknown"


  def fields do
    [
      %{
        "field" => "type",
        "display" => "Messagetype",
      },
      %{
        "field" => "medium",
        "display" => "Medium",
      },
      %{
        "field" => "meter_id",
        "display" => "Meter-ID",
      },
      %{
        "field" => "qualifier",
        "display" => "Qualifier",
      },
      %{
        "field" => "register_value",
        "display" => "Register-Value",
      },
    ]
  end

  def tests() do
    [
      {
        # Meter Reading from Example in PDF
        :parse_hex, "0051294BBC000D000000", %{meta: %{frame_port: 8}}, %{
          header_version: 1,
          medium: "electricity_kwh",
          meter_id: 12340009,
          qualifier: "a-plus",
          register_value: 0.13,
          type: "meter_reading"
        },
      },

      {
        # Status Message from real device
        :parse_hex,  "0169008178E17F98F44A042D7B4F4B000000000000000001", %{meta: %{frame_port: 6}}, %{
          connected_devices: 1,
          firmware_id: "008178E1",
          frame_type: 0,
          is_ack: 0,
          last_downlink_ms: 75,
          node_type: "brige",
          reset_reason: "soft",
          rssi: 0,
          session_info: "joined",
          snr: 0,
          time_s: 1333472516,
          type: "status",
          uptime_ms: 1257543807,
        },
      },

      {
        # MeterReading Message from real device that somehow has no frame header.
        :parse_hex,  "513097F701B8030000", %{meta: %{frame_port: 8}}, %{
          header_version: 1,
          medium: "electricity_kwh",
          meter_id: 33003312,
          qualifier: "a-plus",
          register_value: 9.52,
          type: "meter_reading"
        },
      },

      # frameheader
      #    meterheader
      #         meterid
      #                  timestamp
      #                           register1
      #                                    register2
      # 00 04A2 0FE46503 27AA4F4B 83010000 00000000
      # 00 04A2 0FE46503 AEA64F4B 83010000 00000000
      {
        # MeterReading Message with header v2
        :parse_hex,  "0004A20FE4650327AA4F4B8301000000000000", %{meta: %{frame_port: 8}}, %{
          header_version: 2,
          medium: "electricity_kwh",
          meter_id: 57009167,
          qualifier: "a-plus-a-minus",
          register_value: 3.87,
          register2_value: 0.0,
          type: "meter_reading",
          timestamp: DateTime.from_unix!(1263512103),
          timestamp_unix: 1263512103,
        },
      },


      {
        # another MeterReading Message with header v2
        :parse_hex,  "0004A20FE46503AEA64F4B8301000000000000", %{meta: %{frame_port: 8}}, %{
          header_version: 2,
          medium: "electricity_kwh",
          meter_id: 57009167,
          qualifier: "a-plus-a-minus",
          register_value: 3.87,
          register2_value: 0.0,
          type: "meter_reading",
          timestamp: DateTime.from_unix!(1263511214),
          timestamp_unix: 1263511214,
        },
      },

      {
        # Testing error handler
        :parse_hex,  "", %{meta: %{frame_port: 8}}, [],
      },
    ]
  end
end
