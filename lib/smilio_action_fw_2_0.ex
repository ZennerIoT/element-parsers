defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # ELEMENT IoT Parser for Smilio Action according to Firmware 2.0.1.x
  #
  # Link: https://www.smilio.eu/action
  # Smilio Action is a system of modular connected buttons (between 1 and 5 buttons on the façade)
  # allowing to report multiple events and trigger automated actions through email, SMS, API or webservices.
  #
  # If no readings are created, check the "running mode" the device is in.
  # Configuration Payloads can be generated here: https://skiplyfrance.github.io/configurator.html
  #
  # Buttons on the device:
  #
  # ┌---------------┐
  # |    skipply    |
  # |               |
  # |  1         2  |
  # |               |
  # |       3       |
  # |               |
  # |  4         5  |
  # └---------------┘
  #
  # Changelog
  #   2019-02-14 [mm]: Initial version.
  #   2020-11-26 [jb]: Implemented missing modes CODE, PULSE and Downlink Query Frame.
  #

  # 13.1. « Keep alive » data frame
  # Each 24 hours, Smilio Action sends automatically a monitoring data frame.
  def parse(<<0x01, battery_idle::16, battery_emission::16, 0x64>>, _meta) do
    %{
      message_type: :keep_alive,
      battery_idle: battery_idle,
      battery_emission: battery_emission
    }
  end

  # 13.2. Normal data frame
  # Smilio Action will send a data frame:
  #  •After each push (Instantly Send Mode)
  #  •Periodically in (Periodic Send Mode)
  #  •Periodically and after each push (Dual Send Mode)
  def parse(<<0x02, buttons::binary-10>>, _meta) do
    %{
      message_type: :data_frame,
      event: :push_or_periodically
    }
    |> parse_normal_data_frame(buttons)
  end

  # 13.3. Hall effect sensor activation data frame
  # Whenever the SKIPLY magnetic badge is detected, Smilio Action sendsan data frame.
  def parse(<<0x03, buttons::binary-10>>, _meta) do
    %{
      message_type: :data_frame,
      event: :magnetic_badge
    }
    |> parse_normal_data_frame(buttons)
  end

  # 18.3. Running Mode 8: PULSE
  # This running mode is the same as the running mode 2with one significant difference: counters are reset to zero after the data frame issent
  def parse(<<0x40, buttons::binary-10>>, _meta) do
    %{
      message_type: :data_frame,
      event: :pulse
    }
    |> parse_normal_data_frame(buttons)
  end

  # 18.4.Running Mode 9: CODE
  def parse(
        <<ack1::4, ack2::4, min_since_entering, min_since_last_transmit::16, code2::binary-3,
          code1::binary-3>>,
        _meta
      ) do
    %{
      message_type: :code,
      min_since_entering: min_since_entering,
      min_since_last_transmit: min_since_last_transmit,
      code1: Base.encode16(code1),
      code1_ack: 3 == ack1,
      code2: Base.encode16(code2),
      code2_ack: 3 == ack2
    }
  end

  # 14.2. Downlink Query Frame
  # Each time Smilio Action is turned on, or the user pushes the Reset button, Smilio Action sends a frame with its settings.
  def parse(
        <<0x04, csc::4, eat::4, vvvv::binary-2, tpb, rnm, lwf, tpbq>>,
        _meta
      ) do
    <<a::1, b::1, c::1, d::1, e::1, dtx::11>> = vvvv

    %{
      message_type: :downlink_query,
      event: :boot,
      csc: csc,
      eat: eat,
      tpb: tpb,
      rnm: rnm,
      lwf: lwf,
      tpbq: tpbq,
      lora_dutycycle: 1 == a,
      lora_backoff: 1 == b,
      lora_piggyback: 1 == c,
      lora_force: 1 == d,
      lora_adr: 1 == e,
      dtx: dtx
    }
  end

  def parse(payload, _meta) do
    Logger.info("Unhandled Payload: #{inspect(payload)}")
    []
  end

  defp parse_normal_data_frame(row, <<b1::16, b2::16, b3::16, b4::16, b5::16>>) do
    Map.merge(row, %{
      button1: b1,
      button2: b2,
      button3: b3,
      button4: b4,
      button5: b5
    })
  end

  def fields do
    [
      %{
        "field" => "button1",
        "display" => "Button 1"
      },
      %{
        "field" => "battery_idle",
        "display" => "Battery (Idle Mode)",
        "unit" => "mV"
      },
      %{
        "field" => "battery_emission",
        "display" => "Battery (Emission)",
        "unit" => "mV"
      },
      %{
        "field" => "message_type",
        "display" => "Message Type"
      },
      %{
        "field" => "data_frame_type",
        "display" => "Data Frame Type"
      },
      %{
        "field" => "button2",
        "display" => "Button 2"
      },
      %{
        "field" => "button3",
        "display" => "Button 3"
      },
      %{
        "field" => "button4",
        "display" => "Button 4"
      },
      %{
        "field" => "button5",
        "display" => "Button 5"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "010C800C8064",
        %{},
        %{battery_emission: 3200, battery_idle: 3200, message_type: :keep_alive}
      },
      {
        :parse_hex,
        "020001001000A000230010",
        %{},
        %{
          button1: 1,
          button2: 16,
          button3: 160,
          button4: 35,
          button5: 16,
          event: :push_or_periodically,
          message_type: :data_frame
        }
      },
      {
        :parse_hex,
        "030001001000A000230010",
        %{},
        %{
          button1: 1,
          button2: 16,
          button3: 160,
          button4: 35,
          button5: 16,
          event: :magnetic_badge,
          message_type: :data_frame
        }
      },
      {
        :parse_hex,
        "04 00 AAAA 02 03 04 05",
        %{
          _comment: "Downlink query Frame"
        },
        %{
          csc: 0,
          dtx: 682,
          eat: 0,
          event: :boot,
          lora_adr: true,
          lora_backoff: false,
          lora_dutycycle: true,
          lora_force: false,
          lora_piggyback: true,
          lwf: 4,
          message_type: :downlink_query,
          rnm: 3,
          tpb: 2,
          tpbq: 5
        }
      },
      {
        :parse_hex,
        "4000010000000100000001",
        %{},
        %{
          button1: 1,
          button2: 0,
          button3: 1,
          button4: 0,
          button5: 1,
          event: :pulse,
          message_type: :data_frame
        }
      },
      {
        :parse_hex,
        "30 01 0002 000000 132445",
        %{},
        %{
          code1: "132445",
          code1_ack: true,
          code2: "000000",
          code2_ack: false,
          message_type: :code,
          min_since_entering: 1,
          min_since_last_transmit: 2
        }
      }
    ]
  end
end
