defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Tekelek 766 RF Devices
  # According to documentation:
  #   2018-04-09 CF-5004-01 TEK 766 Payload Data Structure R1.xlsx
  #
  # Changelog
  #   2018-11-29: [jb] Initial version of parser
  #   2019-05-22: [gw] Read tank height and form from device profile. Calculate fill level depending on form.
  #   2020-01-27: [jb] Fixed handling of tank.form profile field.

  # Profile "tank":
  #   Fields:
  #     "height" as Number, default 165cm
  #     "form" as String with possible values: "ball_tank", "lying_cylinder", or default "normal"

  # The TEK 766 Ultrasonic sensor unit can send 6 types of message.
  # The payload message type is defined by the first byte of the Datagram as referenced in the table below.
  #
  # This sensor is sending a STATUS message after start, that already contains the first ullage and temperature which will result in a reading.
  # Then the MEASUREMENT message is send every scheduled_tx_period hours (!) and will contain
  # the current ullage/temperatures plus (if available) the last 3 ullage/temperatures. Just the current will result in a reading.
  # There are ALARM messages, that contain current and previous ullage/temperature, which will result in a reading.

  def profile_name(), do: :tank

  # default height of a tank in cm (Integer). This can be set in the profile of a device with 'height'.
  def default_tank_height(), do: 165

  # Form of the tank, as the percentage is calculated differently with e.g. a ball shaped tank
  # can have the following values: :ball_tank, :lying_cylinder, :normal
  def default_tank_form(), do: :normal

  def preloads do
    [device: [profile_data: [:profile]]]
  end

  # Measurement
  # Data Measurement Upload - periodic on variable schedule
  def parse(
        <<
          0x10,
          # Message type
          0x00,
          # Prod ID TEK766
          alarms :: binary - 1,
          _reserved :: 8,
          readings_binary :: binary
        >>,
        meta
      ) do
    alarms = parse_alarms_binary(alarms)

    [reading | _] = parse_measurement_readings(readings_binary, [], meta)

    reading
    |> Map.merge(alarms)
    |> Map.merge(%{message_type: "measurement"})
  end

  # Status frame
  # The status frame contains some important information, but information which would rarely change and is not required to be transmitted on a daily basis.
  def parse(
        <<
          0x30,
          # Message type
          0x00,
          # Prod ID TEK766
          _reserved :: 8,
          payload :: binary
        >>,
        meta
      ) do
    <<
      hardware_id :: 8,
      software_id :: 16,
      _reserved1 :: 8,
      _reserved2 :: 8,
      unit_rssi :: signed - 8,
      _reserved3 :: 8,
      battery_remaining :: 8,
      measurement_steps :: 16,
      schedule_tx_period :: 8,
      # hours
      ullage :: 16,
      temp :: signed - 8,
      src :: 4,
      srssi :: 4,
      _rest :: bits
    >> = payload

    %{
      message_type: "status",
      hardware_id: hardware_id,
      software_id: software_id,
      unit_rssi: unit_rssi * -1,
      battery_remaining: battery_remaining,
      measurement_steps: measurement_steps,
      scheduled_tx_period: schedule_tx_period,
      ullage: ullage,
      fill_level: get_fill_level(ullage, meta),
      temp: temp,
      src: src,
      srssi: srssi,
    }
  end

  # Alarm frame
  # The alarms frame is structurally similar to a standard measurement frame apart from the different
  # message type (to indicate an immediate alarm notification as opposed to to a scheduled measurement)
  # and that only two readings are sent (the "alarming" reading, plus the previously logged reading.
  def parse(
        <<
          0x45,
          # Message type
          0x00,
          # Prod ID TEK766
          alarms :: binary - 1,
          _reserved :: 8,
          readings_binary :: binary
        >>,
        meta
      ) do

    alarms = parse_alarms_binary(alarms)

    # Expecting up to 2 readings.
    {current, prev} = case parse_measurement_readings(readings_binary, [], meta) do
      [current, %{src: prev_src, srssi: prev_srssi, temp: prev_temp, ullage: prev_ullage}] ->
        {current, %{prev_src: prev_src, prev_srssi: prev_srssi, prev_temp: prev_temp, prev_ullage: prev_ullage}}
      [current] ->
        {current, %{}} # No prev reading available
    end

    current
    |> Map.merge(alarms)
    |> Map.merge(prev)
    |> Map.merge(%{message_type: "alarm"})
  end

  # Catchall for reparsing
  def parse(payload, meta) do
    Logger.info("Unknown payload #{inspect payload} on frame-port: #{inspect get(meta, [:meta, :frame_port])}")
    []
  end

  #--- Internals ---


  def parse_measurement_readings(<<0 :: 16, 0 :: 8, 0::8, rest :: binary>>, acc, meta) do
    parse_measurement_readings(rest, acc, meta) # Not adding unavailable measurements.
  end
  def parse_measurement_readings(<<ullage :: 16, temp :: signed - 8, src :: 4, srssi :: 4, rest :: binary>>, acc, meta) do
    parse_measurement_readings(rest, [%{ullage: ullage, fill_level: get_fill_level(ullage, meta), temp: temp, src: src, srssi: srssi, } | acc], meta)
  end
  def parse_measurement_readings(rest, acc, _) do
    if <<>> != rest do
      Logger.warn("Parser.parse_measurement_readings: Unknown readings binary rest #{inspect rest}")
    end
    Enum.reverse(acc)
  end


  def parse_alarms_binary(<<lim8 :: 1, lim7 :: 1, lim6 :: 1, lim5 :: 1, lim4 :: 1, lim3 :: 1, lim2 :: 1, lim1 :: 1>>) do
    # Return Map of alarms that are != 0
    [
      alarm1: lim1,
      alarm2: lim2,
      alarm3: lim3,
      alarm4: lim4,
      alarm5: lim5,
      alarm6: lim6,
      alarm7: lim7,
      alarm8: lim8,
    ]
    |> Enum.filter(fn ({_key, value}) -> value == 1 end)
    |> Enum.into(%{})
  end

  def get_fill_level(ullage, meta) do
    tank_height = get(meta, [:device, :fields, profile_name(), :height], default_tank_height())
    tank_form = get(meta, [:device, :fields, profile_name(), :form], default_tank_form())

    calculate_fill_level(to_string(tank_form), tank_height, ullage)
  end

  defp calculate_fill_level(_form, tank_height, _ullage) when tank_height <= 0 do
    0 # Cap to 0%
  end
  defp calculate_fill_level(_form, tank_height, ullage) when tank_height < ullage do
    100 # Cap to 100%
  end
  defp calculate_fill_level("ball_tank", tank_height, ullage) do
    tank_radius = tank_height / 2
    volume_tank = (4/3) * :math.pi() * :math.pow(tank_radius, 3)
    # https://de.wikipedia.org/wiki/Kugelsegment
    fill_volume = (:math.pi() / 3) * :math.pow(ullage, 2) * (3 * tank_radius - ullage)

    Float.round(((volume_tank - fill_volume) / volume_tank) * 100, 2)
  end
  defp calculate_fill_level("lying_cylinder", tank_height, ullage) do
    tank_radius = tank_height / 2
    # We only calculate the circle area of the cylinder and the area of the fill level. The width of the cylinder doesn't matter for the fill level.
    cylinder_area = :math.pi() * :math.pow(tank_radius, 2)
    # https://de.wikipedia.org/wiki/Kreissegment with h = ullage and r = tank_radius
    fill_area = :math.pow(tank_radius, 2) * :math.acos(1 - (ullage / tank_radius)) - (tank_radius - ullage) * :math.sqrt(2 * tank_radius * ullage - :math.pow(ullage, 2))

    Float.round(((cylinder_area - fill_area) / cylinder_area) * 100, 2)
  end
  defp calculate_fill_level("normal", tank_height, ullage) do
    Float.round(((tank_height - ullage) / tank_height) * 100, 2)
  end
  defp calculate_fill_level(form, _tank_height, _ullage) do
    raise "Can not calculate fill level for unknown tank form: #{inspect form}"
  end


  def fields do
    [
      %{
        "field" => "message_type",
        "display" => "Nachrichtentyp",
      },
      %{
        "field" => "ullage",
        "unit" => "cm",
        "display" => "Freiraum",
      },
      %{
        "field" => "fill_level",
        "unit" => "%",
        "display" => "Füllstand",
      },
      %{
        "field" => "temp",
        "unit" => "°C",
        "display" => "Temperatur",
      },
      %{
        "field" => "src",
        "display" => "SRC",
      },
      %{
        "field" => "srssi",
        "display" => "SRSSI",
      },
      %{
        "field" => "battery_remaining",
        "unit" => "%",
        "display" => "Batterie",
      },
      %{
        "field" => "scheduled_tx_period",
        "unit" => "hours",
        "display" => "Sendeinterval",
      },
    ]
  end


  def tests() do
    [
      # Measurement
      {
        :parse_hex,
        "10000100018DF8AA018CF8AA018CF8AA018CF8AA",
        %{
          meta: %{
            frame_port: 16,
          },
          device: %{
            fields: %{
              tank: %{
                height: 400,
                form: :normal,
              }
            }
          }
        },
        %{
          alarm1: 1,
          message_type: "measurement",
          src: 10,
          srssi: 10,
          temp: -8,
          ullage: 397,
          fill_level: 0.75
        }
      },

      # Status
      {
        :parse_hex,
        "3000000200023400590062005A0600161B9A",
        %{
          meta: %{
            frame_port: 48,
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :normal,
              }
            }
          }
        },
        %{
          battery_remaining: 98,
          hardware_id: 2,
          measurement_steps: 90,
          message_type: "status",
          scheduled_tx_period: 6,
          software_id: 2,
          src: 9,
          srssi: 10,
          temp: 27,
          ullage: 22,
          fill_level: 78.0,
          unit_rssi: -89
        }
      },

      # Alarm
      {
        :parse_hex,
        "45000100004b18aa00000000",
        %{
          meta: %{
            frame_port: 1
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :normal,
              }
            }
          }
        },
        %{alarm1: 1, message_type: "alarm", src: 10, srssi: 10, temp: 24, ullage: 75, fill_level: 25.0}
      },

      # Real Payload from device
      {
        :parse_hex,
        "10000000001A17AA001A17AA001A17AA001A17AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :normal,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 23, ullage: 26, fill_level: 74.0}
      },
      {
        :parse_hex,
        "30000001010637004D0063016806001A17AA",
        %{
          meta: %{
            frame_port: 48
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :normal,
              }
            }
          }
        },
        %{
          battery_remaining: 99,
          hardware_id: 1,
          measurement_steps: 360,
          message_type: "status",
          scheduled_tx_period: 6,
          software_id: 262,
          src: 10,
          srssi: 10,
          temp: 23,
          ullage: 26,
          fill_level: 74.0,
          unit_rssi: -77
        }
      },
      {
        :parse_hex,
        "30000001010637004D006301680600000000",
        %{
          meta: %{
            frame_port: 48
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :normal,
              }
            }
          }
        },
        %{
          battery_remaining: 99,
          hardware_id: 1,
          measurement_steps: 360,
          message_type: "status",
          scheduled_tx_period: 6,
          software_id: 262,
          src: 0,
          srssi: 0,
          temp: 0,
          ullage: 0,
          fill_level: 100.0,
          unit_rssi: -77
        }
      },
      {
        :parse_hex,
        "10000000001A16AA001A17AA001A18AA001A19AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 52,
                form: :normal,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 22, ullage: 26, fill_level: 50.0}
      },
      { # test ball_tank formula
        :parse_hex,
        "10000000001A16AA001A17AA001A18AA001A19AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 52,
                form: :ball_tank,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 22, ullage: 26, fill_level: 50.0}
      },
      { # test ball_tank formula
        :parse_hex,
        "10000000001A16AA001A17AA001A18AA001A19AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 30,
                form: :ball_tank,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 22, ullage: 26, fill_level: 4.86}
      },
      { # test ball_tank formula
        :parse_hex,
        "10000000001A16AA001A17AA001A18AA001A19AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 400,
                form: :ball_tank,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 22, ullage: 26, fill_level: 98.79}
      },
      { # test lying_cylinder formula
        :parse_hex,
        "10000000001A16AA001A17AA001A18AA001A19AA",
        %{
          meta: %{
            frame_port: 16
          },
          device: %{
            fields: %{
              tank: %{
                height: 100,
                form: :ball_tank,
              }
            }
          }
        },
        %{message_type: "measurement", src: 10, srssi: 10, temp: 22, ullage: 26, fill_level: 83.24}
      },
    ]
  end

end
