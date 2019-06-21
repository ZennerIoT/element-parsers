defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for the DZG Plugin and Bridge using the v2.0 LoRaWAN Frame Format from file "LoRaWAN Frame Format 2.0.pdf".
  #
  # Changelog
  #   2018-11-28 [jb]: Reimplementation according to PDF.
  #   2018-12-03 [jb]: Handling MeterReading messages with missing frame header.
  #   2018-12-19 [jb]: Handling MeterReading messages with header v2. Fixed little encoding for some fields.
  #   2019-02-18 [jb]: Added option add_power_from_last_reading? that will calculate the power between register values.
  #   2019-04-29 [gw]: Also handle medium electricity with qualifier A_Plus.
  #   2019-05-02 [gw]: Return multiple readings with an A_Plus qualifier and a correct timestamp. DON'T USE THIS!
  #   2019-05-13 [gw]: Return only the latest value with A_Plus qualifier.
  #   2019-05-14 [jb]: Added full obis code if available. Added interpolation feature.
  #   2019-05-15 [jb]: Rounding all values as float to a precision of 3 decimals.
  #   2019-07-11 [jb]: Added handling of a-plus-a-minus with register2_value field.

  # Configuration

  # Will use the register_value from previous reading and add the field `power`.
  # Default: true
  def add_power_from_last_reading?(), do: true


  # Flag if interpolated values for 0:00, 0:15, 0:30, 0:45, ... should be calculated
  # Default: true
  def interpolate?(), do: true
  # Minutes between interpolated values
  # Default: 15
  def interpolate_minutes(), do: 15

  # Name of timezone.
  # Default: "Europe/Berlin"
  def timezone(), do: "Europe/Berlin"


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
  def parse(<<0::2, 0::1, 0::1, 0::1, type::3, frame::binary>>, meta) do
    case type do
      0 -> # MeterReadingMessageEncrypted
        parse_meter_reading_message(frame, meta)
      1 -> # StatusMessage
        parse_status_message(frame)
      _ -> # Ignored: FrameTypeRawSerial and FrameTypeIec1107
        Logger.info("Unhandled frame type: #{inspect type}")
        []
    end
  end

  # Handling MeterReading messages without Header.
  def parse(<<frame::binary>>, %{meta: %{frame_port: 8}} = meta) do
    parse_meter_reading_message(frame, meta)
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
  # Matching hard on medium 2=electricity_kwh here, to avoid problems with header v2
  def parse_meter_reading_message(<<1::2, 2::3, qualifier::3, meter_id::32-little, registers::binary>>, meta) do
    medium = 2
    reading = %{
      type: "meter_reading",
      header_version: 1,
      medium: medium_name(medium),
      qualifier: medium_qualifier_name(medium, qualifier),
      meter_id: meter_id,
    }

    reading = case registers do
      <<register_value::32-little>> ->
        reading
        |> Map.put(:register_value, round_as_float(register_value / 100))
        |> add_obis(medium, qualifier, 1, round_as_float(register_value / 100))
        |> add_power_from_last_reading(meta, :register_value, :power)

      <<register_value::32-little, register2_value::32-little>> ->
        reading
        |> Map.put(:register_value, round_as_float(register_value / 100))
        |> add_obis(medium, qualifier, 1, round_as_float(register_value / 100))
        |> add_power_from_last_reading(meta, :register_value, :power)

        |> Map.put(:register2_value, round_as_float(register2_value / 100))
        |> add_obis(medium, qualifier, 2, round_as_float(register2_value / 100))
        |> add_power_from_last_reading(meta, :register2_value, :power)
    end

    [reading] ++ build_missing(reading, :register_value, meta, %{medium: medium, qualifier: qualifier, register_index: 1})
  end

  # Supporting MeterReadingMessageHeaderVersion2 with 2 byte length
  # Problem: the 2 byte header is little endian, so the version flag is at a DIFFERENT position than in MeterReadingMessageHeaderVersion1.
  def parse_meter_reading_message(<<qualifier::8, 2::2, has_timestamp::1, is_compressed::1, medium::4, rest::binary>>, meta) do
    case {{medium, qualifier, has_timestamp, is_compressed}, rest} do
      {{2, 4, 1, 0}, <<meter_id::32-little, timestamp::32-little, register_value::32-little, register2_value::32-little>>} ->
        value = round_as_float(register_value / 100)
        value2 = round_as_float(register2_value / 100)
        reading = create_basic_meter_reading_data(medium, qualifier, meter_id)
        |> add_register_values(timestamp, value, value2)
        |> add_power_from_last_reading(meta, :register_value, :power)
        |> add_power_from_last_reading(meta, :register2_value, :power2)
        |> add_obis(medium, qualifier, 1, value)
        |> add_obis(medium, qualifier, 2, value2)

        [reading]
        ++
        build_missing(reading, :register_value, meta, %{medium: medium, qualifier: qualifier, register_index: 1})
        ++
        build_missing(reading, :register2_value, meta, %{medium: medium, qualifier: qualifier, register_index: 2})

      {{2, 1, 1, 0}, <<meter_id::32-little, rest::binary>>} ->
        create_latest_meter_readings(medium, qualifier, meter_id, meta, rest)
      {header, binary} ->
        Logger.info("Not creating meter reading because not matching header #{inspect header} and reading_data #{Base.encode16 binary}")
        []
    end

  end

  def parse_meter_reading_message(_, _) do
    Logger.info("Unknown MeterReadingData format")
    []
  end

  defp build_missing(%{} = current_data, register_field, meta, %{medium: medium, qualifier: qualifier, register_index: register_index}) do

    if interpolate?() do

      current_value = Map.fetch!(current_data, register_field)
      current_measured_at = Map.fetch!(meta, :transceived_at)
      register_field_string = to_string(register_field)

      case get_last_reading(meta, [{register_field, :_}]) do
        %{data: %{^register_field_string => last_value}, measured_at: last_measured_at} ->

          missing_readings = [
             {%{value: last_value}, [measured_at: last_measured_at]},
             {%{value: current_value}, [measured_at: current_measured_at]},
           ]
           |> TimeSeries.fill_gaps(
                fn datetime_a, datetime_b ->
                  # Calculate all tuples with x=nil between a and b where a value should be interpolated
                  interval = Timex.Interval.new(
                    from: datetime_a |> Timex.to_datetime(timezone()) |> datetime_add_to_multiple_of_minutes(interpolate_minutes()),
                    until: datetime_b,
                    left_open: false,
                    step: [minutes: interpolate_minutes()]
                  )
                  Enum.map(interval, &({nil, [measured_at: &1]}))
                end,
                :linear,
                x_access_path: [Access.elem(1), :measured_at],
                y_access_path: [Access.elem(0)],
                x_pre_calc_fun: &Timex.to_unix/1,
                x_post_calc_fun: &Timex.to_datetime/1,
                y_pre_calc_fun: fn %{value: value} -> value end,
                y_post_calc_fun: &(%{value: &1, _interpolated: true})
              )
           |> Enum.filter(fn ({data, _meta}) -> Map.get(data, :_interpolated, false) end)
           |> Enum.map(fn {%{value: value}, reading_meta} ->
            value = round_as_float(value)
            {
              current_data
              |> Map.take([:type, :medium, :qualifier, :meter_id])
              |> Map.put(register_field, value)
              |> add_obis(medium, qualifier, register_index, value),
              reading_meta
            }
          end)

          missing_readings

        nil ->
          Logger.info("No result for get_last_reading()")
          []

        invalid_prev_reading ->
          Logger.warn("Could not build_missing() because of invalid previous reading: #{inspect invalid_prev_reading}")
          []
      end

    else
      []
    end
  end
  defp build_missing(_current_data, _register_field, _meta, _opts) do
    Logger.warn("Could not build_missing() because of invalid current_data")
    []
  end

  # Will shift 2019-04-20 12:34:56 to   2019-04-20 12:45:00
  defp datetime_add_to_multiple_of_minutes(%DateTime{} = dt, minutes) do
    minute_seconds = minutes * 60
    rem = rem(DateTime.to_unix(dt), minute_seconds)
    Timex.shift(dt, seconds: (minute_seconds - rem))
  end

  # Adds a a key like %{"1-0:1.8.0" => value} for given parameters.
  defp add_obis(data, medium, qualifier, register_index, value) do
    case obis_medium_qualifier(medium, qualifier) do
      [] -> data
      obis_codes ->
        case Enum.at(obis_codes, register_index-1) do
          nil -> data
          obis_code -> Map.put(data, obis_code, value)
        end
    end
  end

  defp create_basic_meter_reading_data(medium, qualifier, meter_id) do
    %{
      type: "meter_reading",
      header_version: 2,
      medium: medium_name_extended(medium),
      qualifier: medium_qualifier_name_extended(medium, qualifier),
      meter_id: meter_id
    }
  end

  defp add_register_values(map, timestamp, register_value, register2_value) do
    map
    |> Map.put(:register_value, register_value)
    |> Map.put(:register2_value, register2_value)
    |> Map.put(:timestamp_unix, timestamp)
    |> Map.put(:timestamp, DateTime.from_unix!(timestamp))
  end

  defp create_latest_meter_readings(medium, qualifier, meter_id, meta, <<timestamp::32-little, register_value::32-little, _other_register_values::binary>>) do
    value = round_as_float(register_value / 100)
    reading = create_basic_meter_reading_data(medium, qualifier, meter_id)
    |> Map.put(:register_value, value)
    |> Map.put(:timestamp_unix, timestamp) # From device, can be wrong if device clock is wrong
    |> Map.put(:timestamp, DateTime.from_unix!(timestamp))
    |> add_power_from_last_reading(meta, :register_value, :power)
    |> add_obis(medium, qualifier, 1, value)

    [reading] ++ build_missing(reading, :register_value, meta, %{medium: medium, qualifier: qualifier, register_index: 1})
  end
  defp create_latest_meter_readings(_medium, _qualifier, _meter_id, _meta, <<>>), do: []

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

  def add_power_from_last_reading(data, meta, register_field, power_field) do
    field_value = Map.get(data, register_field)
    case {add_power_from_last_reading?(), is_nil(field_value)} do
      {true, false} ->
        case get_last_reading(meta, [{register_field, :_}]) do
          %{measured_at: measured_at, data: last_data} ->

            field_last = get(last_data, [register_field])

            now_unix = DateTime.utc_now |> DateTime.to_unix
            reading_unix = measured_at |> DateTime.to_unix

            time_since_last_reading = now_unix - reading_unix

            power = (field_value - field_last) / (time_since_last_reading / 3600)

            power = Float.round(power, 3)

            Map.put(data, power_field, power)
          _ -> data # No previous reading
        end
      _ -> data # Not activated or missing field
    end
  end

  defp round_as_float(value) do
    Float.round(value / 1, 3)
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


  # `1-0:e:8:t` e = energierichtung (1 = plus, 2 = minus), t = tarif (0 = gesamt, 1 = t1, 2 = t2, ...)
  defp obis_medium_qualifier(2, 1), do: ["1-0:1.8.0"] # a-plus
  defp obis_medium_qualifier(2, 4), do: ["1-0:1.8.0", "1-0:2.8.0"] # a-plus-a-minus
  defp obis_medium_qualifier(2, 5), do: ["1-0:2.8.0"] # a-minus
  defp obis_medium_qualifier(2, _), do: []

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

    last_reading_register_value = %{measured_at: test_datetime("2019-01-01T11:34:56Z"), data: %{"register_value" => 0.09}}
    last_reading_register2_value = %{measured_at: test_datetime("2019-01-01T11:34:56Z"), data: %{"register2_value" => 0.0}}

    [
      {
        # Meter Reading from Example in PDF
        :parse_hex, "0051294BBC000D000000",
        %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          %{
            :header_version => 1,
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :qualifier => "a-plus",
            :register_value => 0.13,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.13
          }
        ],
      },

      {
        # Status Message from real device
        :parse_hex,  "0169008178E17F98F44A042D7B4F4B000000000000000001",
        %{meta: %{frame_port: 6}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        %{
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
        :parse_hex,  "513097F701B8030000",
        %{
          meta: %{frame_port: 8},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
          _last_reading_map: %{
            [register_value: :_] => %{measured_at: test_datetime("2019-01-01T12:11:11Z"), data: %{"register_value" => 1.23}},
          },
        },
        [
          %{
            :header_version => 1,
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :power => 0.002,
            :qualifier => "a-plus",
            :register_value => 9.52,
            :type => "meter_reading",
            "1-0:1.8.0" => 9.52
          },
          {
            %{
              :medium => "electricity_kwh",
              :meter_id => 33003312,
              :qualifier => "a-plus",
              :register_value => 2.562,
              :type => "meter_reading",
              "1-0:1.8.0" => 2.562
            },
            [
              measured_at: test_datetime("2019-01-01 12:15:00Z")
            ]
          },
          {
            %{
              :medium => "electricity_kwh",
              :meter_id => 33003312,
              :qualifier => "a-plus",
              :register_value => 7.798,
              :type => "meter_reading",
              "1-0:1.8.0" => 7.798
            },
            [
             measured_at: test_datetime("2019-01-01 12:30:00Z")
            ]
          }
        ],
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
        :parse_hex,  "0004A20FE4650327AA4F4B8301000000000000",
        %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 57009167,
            :qualifier => "a-plus-a-minus",
            :register2_value => 0.0,
            :register_value => 3.87,
            :timestamp => DateTime.from_unix!(1263512103),
            :timestamp_unix => 1263512103,
            :type => "meter_reading",
            "1-0:1.8.0" => 3.87,
            "1-0:2.8.0" => 0.0
          }
        ],
      },


      {
        # another MeterReading Message with header v2
        :parse_hex,  "0004A20FE46503AEA64F4B8301000000000000",
        %{
          meta: %{frame_port: 8},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
        },
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 57009167,
            :qualifier => "a-plus-a-minus",
            :register2_value => 0.0,
            :register_value => 3.87,
            :timestamp => DateTime.from_unix!(1263511214),
            :timestamp_unix => 1263511214,
            :type => "meter_reading",
            "1-0:1.8.0" => 3.87,
            "1-0:2.8.0" => 0.0
          }
        ]
      },

      {
        # Electricity medium with A_Plus qualifier and 3 values
        :parse_hex, "0001A27D29370046237B4BCF0100002E227B4BCF01000062217B4BCF010000",
        %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 3615101,
            :qualifier => "a-plus",
            :register_value => 4.63,
            :timestamp => DateTime.from_unix!(1266361158),
            :timestamp_unix => 1266361158,
            :type => "meter_reading",
            "1-0:1.8.0" => 4.63
          }
        ]
      },

      {
        # Electricity medium with A_Plus qualifier and 3 values
        :parse_hex, "0001A27D29370046237B4BCF0100002E227B4BCF01000062217B4BCF010000",
        %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 3615101,
            :qualifier => "a-plus",
            :register_value => 4.63,
            :timestamp => DateTime.from_unix!(1266361158),
            :timestamp_unix => 1266361158,
            :type => "meter_reading",
            "1-0:1.8.0" => 4.63
          }
        ]
      },

      {
        # Electricity medium with A_Plus qualifier and 3 values
        :parse_hex, "54EDEF6503D59E040000000000",
        %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          %{
            :header_version => 1,
            :medium => "electricity_kwh",
            :meter_id => 57012205,
            :qualifier => "a-plus-a-minus",
            :register_value => 3028.05,
            :register2_value => 0.0,
            :type => "meter_reading",
            "1-0:1.8.0" => 3028.05,
            "1-0:2.8.0" => 3028.05
          }
        ]
      },

      {
        # Electricity medium with A_Plus qualifier and 4 values
        :parse_hex, "0001A277293700F7287A4B1A0400006B287A4B19040000B0277A4B1904000024277A4B19040000",
        %{
          meta: %{frame_port: 8},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
        },
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 3615095,
            :qualifier => "a-plus",
            :register_value => 10.5,
            :timestamp => DateTime.from_unix!(1266297079),
            :timestamp_unix => 1266297079,
            :type => "meter_reading",
            "1-0:1.8.0" => 10.5
          }
        ]
      },

      {
        # Electricity medium with A_Plus qualifier and 4 values and interpolation
        :parse_hex, "0001A277293700F7287A4B1A0400006B287A4B19040000B0277A4B1904000024277A4B19040000",
        %{
          meta: %{frame_port: 8},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
          _last_reading_map: %{
            [register_value: :_] => %{measured_at: test_datetime("2019-01-01T12:11:11Z"), data: %{"register_value" => 1.23}},
          },
        },
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 3615095,
            :power => 0.002,
            :qualifier => "a-plus",
            :register_value => 10.5,
            :timestamp => test_datetime("2010-02-16 05:11:19Z"),
            :timestamp_unix => 1266297079,
            :type => "meter_reading",
            "1-0:1.8.0" => 10.5
          },
          {%{
            :medium => "electricity_kwh",
            :meter_id => 3615095,
            :qualifier => "a-plus",
            :register_value => 2.72,
            :type => "meter_reading",
            "1-0:1.8.0" => 2.72
          }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 3615095,
            :qualifier => "a-plus",
            :register_value => 8.574,
            :type => "meter_reading",
            "1-0:1.8.0" => 8.574
          }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]}
        ]
      },

      {
        # another MeterReading Message with header v2
        :parse_hex,  "0004A20FE46503AEA64F4B8301000000000000",
        %{
          meta: %{frame_port: 8},
          transceived_at: test_datetime("2019-01-01T12:34:56Z"),
        },
        [
          %{
            :header_version => 2,
            :medium => "electricity_kwh",
            :meter_id => 57009167,
            :qualifier => "a-plus-a-minus",
            :register2_value => 0.0,
            :register_value => 3.87,
            :timestamp => DateTime.from_unix!(1263511214),
            :timestamp_unix => 1263511214,
            :type => "meter_reading",
            "1-0:1.8.0" => 3.87,
            "1-0:2.8.0" => 0.0
          }
        ]
      },

      {
        # Testing error handler
        :parse_hex,  "", %{meta: %{frame_port: 8}, transceived_at: test_datetime("2019-01-01T12:34:56Z")}, [],
      },

      {
        # Meter Reading from Example in PDF
        :parse_hex, "0051294BBC000D000000",
        %{
          meta: %{frame_port: 8},
          _last_reading_map: %{
            [register_value: :_] => last_reading_register_value,
          },
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          %{
            :header_version => 1,
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :power => 0.0,
            :qualifier => "a-plus",
            :register_value => 0.13,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.13
          },
          {%{
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :qualifier => "a-plus",
            :register_value => 0.097,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.097
          }, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :qualifier => "a-plus",
            :register_value => 0.107,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.107
          }, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :qualifier => "a-plus",
            :register_value => 0.117,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.117
          }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 12340009,
            :qualifier => "a-plus",
            :register_value => 0.127,
            :type => "meter_reading",
            "1-0:1.8.0" => 0.127
          }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]}
        ]
      },

      {
        # MeterReading Message from real device that somehow has no frame header.
        :parse_hex,  "513097F701B8030000",
        %{
          meta: %{frame_port: 8},
          _last_reading_map: %{
            [register_value: :_] => last_reading_register_value,
          },
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
          %{
            :header_version => 1,
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :power => 0.002,
            :qualifier => "a-plus",
            :register_value => 9.52,
            :type => "meter_reading",
            "1-0:1.8.0" => 9.52
          },
          {%{
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :qualifier => "a-plus",
            :register_value => 1.672,
            :type => "meter_reading",
            "1-0:1.8.0" => 1.672
          }, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :qualifier => "a-plus",
            :register_value => 4.03,
            :type => "meter_reading",
            "1-0:1.8.0" => 4.03
          }, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :qualifier => "a-plus",
            :register_value => 6.387,
            :type => "meter_reading",
            "1-0:1.8.0" => 6.387
          }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
          {%{
            :medium => "electricity_kwh",
            :meter_id => 33003312,
            :qualifier => "a-plus",
            :register_value => 8.745,
            :type => "meter_reading",
            "1-0:1.8.0" => 8.745
          }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]}
        ]
      },

      {
        # MeterReading Message with header v2
        :parse_hex,  "0004A20FE4650327AA4F4B8301000000000000",
        %{
          meta: %{frame_port: 8},
          _last_reading_map: %{
            [register_value: :_] => last_reading_register_value,
            [register2_value: :_] => last_reading_register2_value,
          },
          transceived_at: test_datetime("2019-01-01T12:34:56Z")
        },
        [
        %{
          :header_version => 2,
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :power => 0.001,
          :power2 => 0.0,
          :qualifier => "a-plus-a-minus",
          :register2_value => 0.0,
          :register_value => 3.87,
          :timestamp => test_datetime("2010-01-14 23:35:03Z"),
          :timestamp_unix => 1263512103,
          :type => "meter_reading",
          "1-0:1.8.0" => 3.87,
          "1-0:2.8.0" => 0.0
        },
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register_value => 0.724,
          :type => "meter_reading",
          "1-0:1.8.0" => 0.724
          }, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register_value => 1.669,
          :type => "meter_reading",
          "1-0:1.8.0" => 1.669
          }, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register_value => 2.614,
          :type => "meter_reading",
          "1-0:1.8.0" => 2.614
          }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register_value => 3.559,
          :type => "meter_reading",
          "1-0:1.8.0" => 3.559
          }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register2_value => 0.0,
          :type => "meter_reading",
          "1-0:2.8.0" => 0.0
          }, [measured_at: test_datetime("2019-01-01 11:45:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register2_value => 0.0,
          :type => "meter_reading",
          "1-0:2.8.0" => 0.0
          }, [measured_at: test_datetime("2019-01-01 12:00:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register2_value => 0.0,
          :type => "meter_reading",
          "1-0:2.8.0" => 0.0
          }, [measured_at: test_datetime("2019-01-01 12:15:00Z")]},
        {%{
          :medium => "electricity_kwh",
          :meter_id => 57009167,
          :qualifier => "a-plus-a-minus",
          :register2_value => 0.0,
          :type => "meter_reading",
          "1-0:2.8.0" => 0.0
          }, [measured_at: test_datetime("2019-01-01 12:30:00Z")]}
        ]
      },
    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end

end