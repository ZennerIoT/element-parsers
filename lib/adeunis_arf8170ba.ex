defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for Adeunis ARF8170BA Devices
  #
  # Supported Part Numbers:
  #   - ARF8170BA DRY CONTACTS LoRaWAN® EU863-870
  #     - https://www.adeunis.com/en/produit/dry-contacts-2/
  #   - ARF8170BA-B02 DOUBLE LEVEL SENSOR LoRaWAN® EU863-870
  #     - https://www.adeunis.com/en/produit/double-level-sensor-fluid-level/
  #     - Channel1 = Top level sensor (tor1)
  #     - Channel2 = Down level sensor (tor2)
  #
  # Payloads with 4 counter inputs, outputs are not yet interpreted.
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2020-12-07 [jb]: Parser REWRITE, renamed fields. Supporting ARF8170BA-B02.
  #   2021-02-24 [jb]: Fixed values of channel*_state*.

  # 4.1.2 Product configuration data frames
  def parse(
        <<0x10, status::binary-1, s300, s301, s320::binary-1, s321::binary-1, s322::binary-1,
          s323::binary-1, s306::8, _rest::binary>>,
        _meta
      ) do
    %{
      frame_type: :device_configuration,
      keepalive_time: s300 * 10,
      transmission_period: s301 * 10,
      config_mode:
        case s306 do
          0 -> :park
          1 -> :production
          2 -> :test
          3 -> :reply
          _ -> "unknown_#{s306}"
        end
    }
    |> parse_tor_config(s320, :input1_type, :input1_duration)
    |> parse_tor_config(s321, :input2_type, :input2_duration)
    |> parse_tor_config(s322, :input3_type, :input3_duration)
    |> parse_tor_config(s323, :input4_type, :input4_duration)
    |> parse_status(status)
  end

  # 4.1.3 Network configuration data frames
  def parse(
        <<0x20, status::binary-1, adr, mode, _rest::binary>>,
        _meta
      ) do
    %{
      frame_type: :network_configuration,
      lora_adr: adr,
      lora_mode:
        case mode do
          0 -> :abp
          1 -> :otaa
          _ -> "unknown_#{mode}"
        end
    }
    |> parse_status(status)
  end

  # 4.1.4 Keep Alive frame
  def parse(
        <<0x30, status::binary-1, _rest::binary>>,
        _meta
      ) do
    %{
      frame_type: :keep_alive
    }
    |> parse_status(status)
  end

  # 4.1.6 Data Frame
  def parse(
        <<0x40, status::binary-1, channel1::16, channel2::16, channel3::16, channel4::16,
          details::binary-1, _rest::binary>>,
        _meta
      ) do
    <<
      ch4_prev::1,
      ch4_state::1,
      ch3_prev::1,
      ch3_state::1,
      ch2_prev::1,
      ch2_state::1,
      ch1_prev::1,
      ch1_state::1
    >> = details

    %{
      frame_type: :data_frame,
      channel1: channel1,
      channel1_state: ch1_state,
      channel1_state_prev: ch1_prev,
      channel2: channel2,
      channel2_state: ch2_state,
      channel2_state_prev: ch2_prev,
      channel3: channel3,
      channel3_state: ch3_state,
      channel3_state_prev: ch3_prev,
      channel4: channel4,
      channel4_state: ch4_state,
      channel4_state_prev: ch4_prev
    }
    |> parse_status(status)
  end

  def parse(
        <<code, _rest::binary>>,
        _meta
      ) do
    %{
      frame_type: "unknown_#{code}"
    }
  end

  def parse(payload, meta) do
    Logger.warn(
      "Could not parse payload #{inspect(payload)} with frame_port #{
        inspect(get_in(meta, [:meta, :frame_port]))
      }"
    )

    []
  end

  defp parse_tor_config(row, <<type::4, duration::4>>, name_type, name_duration) do
    Map.merge(row, %{
      name_type =>
        case type do
          0 -> :disabled
          1 -> :periodic_high
          2 -> :periodic_low
          3 -> :periodic_both
          4 -> :event_high
          5 -> :event_low
          6 -> :event_both
          7 -> :output_default1
          8 -> :output_default0
          _ -> "unknown_#{type}"
        end,
      name_duration =>
        case duration do
          0 -> 0
          1 -> 10
          2 -> 20
          3 -> 50
          4 -> 100
          5 -> 200
          6 -> 500
          7 -> 1000
          8 -> 2000
          9 -> 5000
          10 -> 10_000
          11 -> 20_000
          12 -> 40_000
          13 -> 60_000
          14 -> 300_000
        end
    })
  end

  defp parse_status(
         row,
         <<frame_counter::3, _reserved::1, command_done::1, hw_error::1, low_bat::1,
           config_set::1>>
       ) do
    Map.merge(row, %{
      frame_counter: frame_counter,
      command_done: command_done,
      hw_error: hw_error,
      battery_low: low_bat,
      config_set: config_set
    })
  end

  def fields() do
    [
      %{
        "field" => "channel1",
        "display" => "Channel1"
      },
      %{
        "field" => "channel2",
        "display" => "Channel2"
      },
      %{
        "field" => "channel3",
        "display" => "Channel3"
      },
      %{
        "field" => "channel4",
        "display" => "Channel4"
      },
      %{
        "field" => "keepalive_time",
        "display" => "Keepalive",
        "unit" => "min"
      },
      %{
        "field" => "transmission_period",
        "display" => "Transmission Period",
        "unit" => "min"
      },
      %{
        "field" => "frame_type",
        "display" => "FrameType"
      }
    ] ++
      Enum.map(
        ~w(battery_low command_done config_set config_mode frame_counter hw_error lora_adr lora_mode),
        fn name ->
          %{
            "field" => to_string(name),
            "display" => to_string(name)
          }
        end
      ) ++
      Enum.flat_map(1..4, fn i ->
        [
          %{
            "field" => "input#{i}_duration",
            "display" => "input#{i}_duration"
          },
          %{
            "field" => "input#{i}_type",
            "display" => "input#{i}_type"
          },
          %{
            "field" => "channel#{i}_state",
            "display" => "channel#{i}_state"
          },
          %{
            "field" => "channel#{i}_state_prev",
            "display" => "channel#{i}_state_prev"
          }
        ]
      end)
  end

  def tests() do
    [
      {:parse_hex, "10 AB 90 48 73 00 b4 32 01", %{_comment: "device config from docs."},
       %{
         battery_low: 1,
         command_done: 1,
         config_mode: :production,
         config_set: 1,
         frame_counter: 5,
         frame_type: :device_configuration,
         hw_error: 0,
         input1_duration: 50,
         input1_type: :output_default1,
         input2_duration: 0,
         input2_type: :disabled,
         input3_duration: 100,
         input3_type: "unknown_11",
         input4_duration: 20,
         input4_type: :periodic_both,
         keepalive_time: 1440,
         transmission_period: 720
       }},
      {:parse_hex, "20 AB 01 01", %{_comment: "network config from docs."},
       %{
         battery_low: 1,
         command_done: 1,
         config_set: 1,
         frame_counter: 5,
         frame_type: :network_configuration,
         hw_error: 0,
         lora_adr: 1,
         lora_mode: :otaa
       }},
      {:parse_hex, "30 AB", %{_comment: "keep alive from docs."},
       %{
         battery_low: 1,
         command_done: 1,
         config_set: 1,
         frame_counter: 5,
         frame_type: :keep_alive,
         hw_error: 0
       }},
      {:parse_hex, "40 AB00F1 0002 0001 0000 9C", %{_comment: "data frame from docs."},
       %{
         battery_low: 1,
         channel1: 241,
         channel1_state: 0,
         channel1_state_prev: 0,
         channel2: 2,
         channel2_state: 1,
         channel2_state_prev: 1,
         channel3: 1,
         channel3_state: 1,
         channel3_state_prev: 0,
         channel4: 0,
         channel4_state: 0,
         channel4_state_prev: 1,
         command_done: 1,
         config_set: 1,
         frame_counter: 5,
         frame_type: :data_frame,
         hw_error: 0
       }},
      {:parse_hex, "FF", %{_comment: "unknown frame"}, %{frame_type: "unknown_255"}}
    ]
  end
end
