defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for NKE Watteco Smart Plug
  #
  # Documentation: http://support.nke-watteco.com/smartplug/
  #
  # Changelog
  #   2019-00-00 [zh]: Initial Version.
  #   2020-08-20 [jb]: Added tests, refactoring.

  def parse(<<0x11, 0x0A, _header::40, status::8>>, %{meta: %{frame_port: 125}}) do
    %{
      type: :relaystatus,
      relay_status: status,
    }
  end
  def parse(<<0x11, 0x0A, _header::48, body::binary>>, %{meta: %{frame_port: 125}}) do
    %{}
    |> parse_body(body)
  end
  def parse(<<0x11, 0x01, _header::56, body::binary>>, %{meta: %{frame_port: 125}}) do
    %{}
    |> parse_body(body)
  end


  def parse(payload, meta) do
    Logger.info("Unhandled meta.frame_port: #{inspect get_in(meta, [:meta, :frame_port])} with payload #{inspect payload}")
    []
  end

  defp parse_body(acc, <<active_energy::24, reactive_energy::24, samples::16, active_power::16, reactive_power::16>>) do
    Map.merge(acc, %{
      type: :report,
      active_energy: active_energy,
      reactive_energy: reactive_energy,
      samples: samples,
      active_power: active_power,
      reactive_power: reactive_power,
    })
  end

  defp parse_body(acc, <<freq::16, freq_min::16, freq_max::16, vrms::16, vrms_min::16, vrms_max::16, vpeak::16, vpeak_min::16, vpeak_max::16, overvoltage_nr::16, sag_nr::16, brownout_nr::16>>) do
    Map.merge(acc, %{
      type: :powerquality,
      freq: (freq+22232)/1000,
      freq_min: (freq_min+22232)/1000,
      freq_max: (freq_max+22232)/1000,
      vrms: vrms/10,
      vrms_min: vrms_min/10,
      vrms_max: vrms_max/10,
      vpeak: vpeak/10,
      vpeak_min: vpeak_min/10,
      vpeak_max: vpeak_max/10,
      overvoltage_nr: overvoltage_nr,
      sag_nr: sag_nr,
      brownout_nr: brownout_nr,
    })
  end

  defp parse_body(acc, unknown) do
    Map.merge(acc, %{
      unparseable_binary: "#{inspect unknown}",
    })
  end


  def fields do
    [
      %{
        field: "relay_status",
        display: "relay"
      },
      %{
        field: "active_energy",
        display: "A+",
        unit: "Wh"
      },
      %{
        field: "reactive_energy",
        display: "+Ri",
        unit: "varh"
      },
      %{
        field: "samples",
        display: "samples"
      },
      %{
        field: "active_power",
        display: "P",
        unit: "W"
      },
      %{
        field: "reactive_power",
        display: "Q",
        unit: "var"
      },
      %{
        field: "freq",
        display: "freq",
        unit: "Hz"
      },
      %{
        field: "freq_min",
        display: "freq min",
        unit: "Hz"
      },
      %{
        field: "freq_max",
        display: "freq max",
        unit: "Hz"
      },
      %{
        field: "vrms",
        display: "Vrms",
        unit: "V"
      },
      %{
        field: "vrms_min",
        display: "Vrms min",
        unit: "V"
      },
      %{
        field: "vrms_max",
        display: "Vrms max",
        unit: "V"
      },
      %{
        field: "vpeak",
        display: "Vpeak",
        unit: "V"
      },
      %{
        field: "vpeak_min",
        display: "Vpeak min",
        unit: "V"
      },
      %{
        field: "vpeak_max",
        display: "Vpeak max",
        unit: "V"
      },
      %{
        field: "sag_nr",
        display: "Sag nr"
      },
      %{
        field: "brownout",
        display: "brownout",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "110A00520000410C000001000000000700000000",
        %{meta: %{frame_port: 125}},
        %{
          active_energy: 1,
          active_power: 0,
          reactive_energy: 0,
          reactive_power: 0,
          samples: 7,
          type: :report
        }
      },

      {
        :parse_hex,
        "11010052000000410C000250FFFE5D044F00000000",
        %{meta: %{frame_port: 125}},
        %{
          active_energy: 592,
          active_power: 0,
          reactive_energy: 16776797,
          reactive_power: 0,
          samples: 1103,
          type: :report
        }
      },

      {
        :parse_hex,
        "110A8052000041186C956BD86D6908EB08CF09280C7B0C620E76000000000003",
        %{meta: %{frame_port: 125}},
        %{
          brownout_nr: 3,
          freq: 50.029,
          freq_max: 50.241,
          freq_min: 49.84,
          overvoltage_nr: 0,
          sag_nr: 0,
          type: :powerquality,
          vpeak: 319.5,
          vpeak_max: 370.2,
          vpeak_min: 317.0,
          vrms: 228.3,
          vrms_max: 234.4,
          vrms_min: 225.5
        }
      },

      {
        :parse_hex,
        "1101805200000041186C896BD86D6908FB08CF09280C930C620E76000000000003",
        %{meta: %{frame_port: 125}},
        %{
          brownout_nr: 3,
          freq: 50.017,
          freq_max: 50.241,
          freq_min: 49.84,
          overvoltage_nr: 0,
          sag_nr: 0,
          type: :powerquality,
          vpeak: 321.9,
          vpeak_max: 370.2,
          vpeak_min: 317.0,
          vrms: 229.9,
          vrms_max: 234.4,
          vrms_min: 225.5
        }
      },

      {
        :parse_hex,
        "110A000600001001",
        %{meta: %{frame_port: 125}},
        %{relay_status: 1, type: :relaystatus}
      },
    ]
  end

end

