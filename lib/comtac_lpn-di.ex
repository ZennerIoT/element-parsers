defmodule Parser do
  use Platform.Parsing.Behaviour

  # ELEMENT IoT Parser for comtac LPN DI
  #
  # https://www.comtac.ch/de/produkte/lora/ios/lpn-di.html
  #

  # Changelog
  #   2018-10-01/jb: Initial Version from Document E1347-LPN_DI_EN_V0.04.pdf

  def parse(<<
    21, app_main_version, app_sub_version,
    rssi_value, snr_value::signed,
    di_state::binary-1,
    di1_counter::32-little, di2_counter::32-little,
    di1_secs_change::24-little, di2_secs_change::24-little
  >>, %{meta: %{frame_port: 3}}) do
    <<
      di1_state::1,
      di2_state::1,
      di1_changed::1,
      di2_changed::1,
      input_variant::1,
      _::2,
      error_supply_24v::1
    >> = di_state
    %{
      software: "v#{app_main_version}.#{app_sub_version}",
      rssi: (rssi_value * -1),
      snr: snr_value,

      di1_state: di1_state,
      di1_changed: di1_changed,
      di1_counter: di1_counter,
      di1_secs_change: format_secs_change(di1_secs_change),

      di2_state: di2_state,
      di2_changed: di2_changed,
      di2_counter: di2_counter,
      di2_secs_change: format_secs_change(di2_secs_change),

      input_variant: %{0 => :di, 1 => :s0}[input_variant],
      error_supply_24v: error_supply_24v
    }
  end

  defp format_secs_change(0xFFFFFF), do: nil
  defp format_secs_change(secs), do: secs

  def fields do
    [
      %{
        "field" => "software",
        "display" => "Software-Ver.",
      },
      %{
        "field" => "error_supply_24v",
        "display" => "Error 24v Supply",
      },
      %{
        "field" => "input_variant",
        "display" => "Input Variant",
      },

      %{
        "field" => "di1_changed",
        "display" => "DI1-Changed",
      },
      %{
        "field" => "di1_counter",
        "display" => "DI1-Counter",
      },
      %{
        "field" => "di1_state",
        "display" => "DI1-Status",
      },
      %{
        "field" => "di1_secs_change",
        "display" => "DI1-ChangeAfter",
        "unit" => "s"
      },

      %{
        "field" => "di2_changed",
        "display" => "DI2-Changed",
      },
      %{
        "field" => "di2_counter",
        "display" => "DI2-Counter",
      },
      %{
        "field" => "di2_state",
        "display" => "DI2-Status",
      },
      %{
        "field" => "di2_secs_change",
        "display" => "DI2-ChangeAfter",
        "unit" => "s"
      },

      %{
        "field" => "rssi",
        "display" => "RSSI",
        "unit" => "dBm",
      },
      %{
        "field" => "snr",
        "display" => "SNR",
        "unit" => "dB",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "15000266FF100000000000000000FFFFFFFFFFFF", %{meta: %{frame_port: 3}}, %{
          software: "v0.2",
          di1_changed: 0,
          di1_counter: 0,
          di1_secs_change: nil,
          di1_state: 0,
          di2_changed: 1,
          di2_counter: 0,
          di2_secs_change: nil,
          di2_state: 0,
          error_supply_24v: 0,
          input_variant: :di,
          rssi: -102,
          snr: -1
        }
      },
      {
        :parse_hex, "1500026704100000000000000000FFFFFFFFFFFF", %{meta: %{frame_port: 3}}, %{
          software: "v0.2",
          di1_changed: 0,
          di1_counter: 0,
          di1_secs_change: nil,
          di1_state: 0,
          di2_changed: 1,
          di2_counter: 0,
          di2_secs_change: nil,
          di2_state: 0,
          error_supply_24v: 0,
          input_variant: :di,
          rssi: -103,
          snr: 4
        }
      },
    ]
  end

end
