defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for NKE Watteco Remote Temp
  #
  # Link: http://www.nke-watteco.com/product/lora-remote-temperature-sensor/
  # Documentation: http://support.nke-watteco.com/remote-temperature/
  #
  # Changelog
  #   2019-11-18 [jb]: Initial implementation.
  #

  # Temperature
  def parse(<<fctrl, 0x0A, 0x04, 0x02, 0x00, 0x00, 0x29, temperature::integer-signed-16>> = payload, %{meta: %{frame_port: 125}} = meta) do
    with {:ok, endpoint} <- fctrl_to_endppoint(fctrl) do
      %{
        type: :temperature,
        endpoint: endpoint,
        temperature: temperature/100,
      }
    else
      error -> fail(error, payload, meta)
    end
  end

  # Battery report
  def parse(<<fctrl, 0x0A, 0x00, 0x50, 0x00, 0x06, 0x41, 0x07, _current_power_mode, _avail_power_sources, voltage::32, _current_power_source>> = payload, %{meta: %{frame_port: 125}} = meta) do
    with {:ok, endpoint} <- fctrl_to_endppoint(fctrl) do
      %{
        type: :power,
        endpoint: endpoint,
        battery: voltage / 1000, # Millivolt -> Volt
      }
    else
      error -> fail(error, payload, meta)
    end
  end

  #

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def fail(error, payload, meta) do
    Logger.warn("NKE Parser with payload #{inspect payload} and frame_port #{inspect get_in(meta, [:meta, :frame_port])} failed with: #{inspect error}")
    []
  end


  # See: http://support.nke-watteco.com/ino/#ApplicativeLayer
  def fctrl_to_endppoint(fctrl) do
    case fctrl do
      0x11 -> {:ok, 0}
      0x31 -> {:ok, 1}
      0x51 -> {:ok, 2}
      0x71 -> {:ok, 3}
      0x91 -> {:ok, 4}
      0xB1 -> {:ok, 5}
      0xD1 -> {:ok, 6}
      0xF1 -> {:ok, 7}
      0x13 -> {:ok, 8}
      0x33 -> {:ok, 9}
      _ -> {:error, :unknown_fctrl}
    end
  end

  def fields do
    [
      %{
        field: "temperature",
        display: "Temperature",
        unit: "°C",
      },
      %{
        field: "battery",
        display: "Battery",
        unit: "V",
      },
      %{
        field: "endpoint",
        display: "Endpoint",
      },
      %{
        field: "type",
        display: "Type",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "11 0A 0402000029090A", %{meta: %{frame_port: 125}},
        %{endpoint: 0, temperature: 23.14, type: :temperature}
      },

      {
        :parse_hex, "11 0a 04 02 00 00 29 00 64", %{meta: %{frame_port: 125}},
        %{endpoint: 0, temperature: 1.0, type: :temperature}
      },

      {
        :parse_hex, "110A0402000029FFDB", %{meta: %{frame_port: 125}},
        %{endpoint: 0, temperature: -0.37, type: :temperature}
      },

      {
        :parse_hex, "11 0A 0050 0006 41 07 010500000DE304", %{meta: %{frame_port: 125}},
        %{battery: 3.555, endpoint: 0, type: :power}
      },
    ]
  end
end
