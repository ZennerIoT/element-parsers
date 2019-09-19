defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for GlobalsSat GPS Tracker
  # According to documentation provided by GlobalSat
  # Link: http://www.globalsat.com.tw/en/product-199335/LoRaWAN%E2%84%A2-Compliant-GPS-Tracker-LT-100-Series.html#a
  #
  # Changelog:
  #   2019-xx-xx [jb]: Initial implementation.
  #   2019-09-06 [jb]: Added parsing catchall for unknown payloads.
  #   2019-09-19 [jb]: Ignoring invalid payloads. Handling missing GPS fix.
  #

  def parse(<<0, fix::2, report::6, bat, lat::32, lon::32>>, %{meta: %{frame_port: 2}}) do

    report = case report do
      2 -> "Periodic mode report"
      4 -> "Motion mode static report"
      5 -> "Motion mode moving report"
      6 -> "Motion mode static to moving report"
      7 -> "Motion mode moving to static report"
      14 -> "Help report"
      15 -> "Low battery alarm report"
      17 -> "Power on (temperature)"
      19 -> "Power off (low battery)"
      20 -> "Power off (temperature)"
      24 -> "Fall advisory report"
      27 -> "Fpending report"
      unknown -> "unknown:#{unknown}"
    end

    reading = %{
      battery: bat, # Percent
      report_type: report,
      fix: Map.get(%{0 => "no-fix", 1 => "2d", 2 => "3d"}, fix, :unknown),
    }

    opts = if fix in [1, 2] do
      [location: {lon*0.000001, lat*0.000001}]
    else
      []
    end

    {reading, opts}
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def tests() do
    [
      {
        :parse_hex, "00825902E5C4BF008E9E78", %{meta: %{frame_port: 2}}, {
          %{battery: 89, fix: "3d", report_type: "Periodic mode report"},
          [location: {9.34668, 48.612542999999995}]
        }
      },
      {
        :parse_hex, "00825B02E5C211008E5D1E", %{meta: %{frame_port: 2}}, {
          %{battery: 91, fix: "3d", report_type: "Periodic mode report"},
          [location: {9.32995, 48.611857}]
        }
      },
      {
        # Undocumented payload send by device.
        :parse_hex, "5FAD414324CE2638BF22FE", %{meta: %{frame_port: 2}}, []
      },
    ]
  end

end
