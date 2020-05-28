defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for second version of eBZ-Zähler.
  #
  # Changelog:
  #   2020-05-27 [nk]: Initial implementation of new version
  #

  def parse(<<_version::1, _options::1, 3::6, _more::1, _num_tuples::7, tuples::binary>>, %{meta: %{frame_port: 15}}) do
    %{}
    |> Map.merge(parse_tuples(tuples))
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  def parse_tuples(<<id::8, 0::1, len::7, data::unit(8)-size(len)-binary, rest::binary>>) when id in 12..24 do
    <<unit::8, scaler::8-signed, data::binary>> = data
    unit = parse_unit(unit)
    value = data
    |> :binary.decode_unsigned()
    |> scale(scaler)
    %{
      "#{id_to_sting(id)}" => value,
      "#{id_to_sting(id)}_unit" => unit
    }
    |> Map.merge(parse_tuples(rest))
  end
  def parse_tuples(<<id::8, 0::1, len::7, data::unit(8)-size(len)-binary, rest::binary>>) when id in [0, 1, 2, 3, 4, 8, 10, 11] do
    data = if String.printable?(data) do
      data
    else
      Base.encode16(data)
    end
    %{
      "#{id_to_sting(id)}" => data # should be ascii coded
    }
    |> Map.merge(parse_tuples(rest))
  end
  def parse_tuples(<<9, 10, 9, sparte, manufacturer::binary-3, fabrication_block, num::integer-32, rest::binary>>) do
    num = String.pad_leading("#{num}", 8, "0")
    fabrication_block = String.pad_leading("#{fabrication_block}", 2, "0")
    %{
      "#{id_to_sting(9)}" => "#{sparte}#{manufacturer}#{fabrication_block}#{num}"
    }
    |> Map.merge(parse_tuples(rest))
  end
  def parse_tuples(<<id::8, 0::1, len::7, data::unit(8)-size(len)-binary, rest::binary>>) do
    %{
      "id_#{id}_unknown" => Base.encode16(data)
    }
    |> Map.merge(parse_tuples(rest))
  end
  def parse_tuples(<<>>) do
    %{}
  end
  def parse_tuples(<<rest::binary>>) do
    %{"parsing_rest_error" => Base.encode16(rest)}
  end

  defp id_to_sting(id) do
    #    _doc = """
    #    ID_OBIS_199_130_3 Herstelleridentifikation
    #    ID_OBIS_0_0_9 Server-ID
    #    ID_OBIS_96_50_1 Herstelleridentifikation
    #    ID_OBIS_96_1_0 Server-ID
    #    """

    Enum.at(id_strings(), id)
  end

  defp id_strings() do
    ~w(
    ID_FIRMWARE_VERSION
    ID_OBIS_MAP_SUMMED
    ID_OBIS_MAP_REPORT
    ID_OBIS_PERIOD
    ID_ERRORS
    ID_RESERVED_1
    ID_RESERVED_2
    ID_RESERVED_3
    ID_OBIS_199_130_3
    ID_OBIS_0_0_9
    ID_OBIS_96_50_1
    ID_OBIS_96_1_0
    ID_OBIS_1_8_0
    ID_OBIS_1_8_1
    ID_OBIS_1_8_2
    ID_OBIS_2_8_0
    ID_OBIS_2_8_1
    ID_OBIS_2_8_2
    ID_OBIS_16_7_0
    ID_OBIS_36_7_0
    ID_OBIS_56_7_0
    ID_OBIS_76_7_0
    ID_OBIS_32_7_0
    ID_OBIS_52_7_0
    ID_OBIS_72_7_0
    )
  end

  defp parse_unit(unit_num) do
    case unit_num do
      # time				year			52*7*24*60*60 s
      1 -> "a"
      # time				month			31*24*60*60 s
      2 -> "mo"
      # time				week			7*24*60*60 s
      3 -> "wk"
      # time				day			24*60*60 s
      4 -> "d"
      # time				hour			60*60 s
      5 -> "h"
      # time				min			60 s
      6 -> "min."
      # time (t)			second			s
      7 -> "s"
      # (phase) angle		degree			rad*180/π
      8 -> "°"
      # temperature (T)		degree celsius		K-273.15
      9 -> "°C"
      # (local) currency
      10 -> "currency"
      # length (l)			metre			m
      11 -> "m"
      # speed (v)			metre per second	m/s
      12 -> "m/s"
      # volume (V)			cubic metre		m³
      13 -> "m³"
      # corrected volume		cubic metre		m³
      14 -> "m³"
      # volume flux			cubic metre per hour 	m³/(60*60s)
      15 -> "m³/h"
      # corrected volume flux	cubic metre per hour 	m³/(60*60s)
      16 -> "m³/h"
      # volume flux						m³/(24*60*60s)
      17 -> "m³/d"
      # corrected volume flux				m³/(24*60*60s)
      18 -> "m³/d"
      # volume			litre			10-3 m³
      19 -> "l"
      # mass (m)			kilogram
      20 -> "kg"
      # force (F)			newton
      21 -> "N"
      # energy			newtonmeter		J = Nm = Ws
      22 -> "Nm"
      # pressure (p)			pascal			N/m²
      23 -> "Pa"
      # pressure (p)			bar			10⁵ N/m²
      24 -> "bar"
      # energy			joule			J = Nm = Ws
      25 -> "J"
      # thermal power		joule per hour		J/(60*60s)
      26 -> "J/h"
      # active power (P)		watt			W = J/s
      27 -> "W"
      # apparent power (S)		volt-ampere
      28 -> "VA"
      # reactive power (Q)		var
      29 -> "var"
      # active energy		watt-hour		W*(60*60s)
      30 -> "Wh"
      # apparent energy		volt-ampere-hour	VA*(60*60s)
      31 -> "VAh"
      # reactive energy		var-hour		var*(60*60s)
      32 -> "varh"
      # current (I)			ampere			A
      33 -> "A"
      # electrical charge (Q)	coulomb			C = As
      34 -> "C"
      # voltage (U)			volt			V
      35 -> "V"
      # electr. field strength (E)	volt per metre
      36 -> "V/m"
      # capacitance (C)		farad			C/V = As/V
      37 -> "F"
      # resistance (R)		ohm			Ω = V/A
      38 -> "Ω"
      # resistivity (ρ)		Ωm
      39 -> "Ωm²/m"
      # magnetic flux (Φ)		weber			Wb = Vs
      40 -> "Wb"
      # magnetic flux density (B)	tesla			Wb/m2
      41 -> "T"
      # magnetic field strength (H)	ampere per metre	A/m
      42 -> "A/m"
      # inductance (L)		henry			H = Wb/A
      43 -> "H"
      # frequency (f, ω)		hertz			1/s
      44 -> "Hz"
      # R_W							(Active energy meter constant or pulse value)
      45 -> "1/(Wh)"
      # R_B							(reactive energy meter constant or pulse value)
      46 -> "1/(varh)"
      # R_S							(apparent energy meter constant or pulse value)
      47 -> "1/(VAh)"
      # volt-squared hour		volt-squaredhours	V²(60*60s)
      48 -> "V²h"
      # ampere-squared hour		ampere-squaredhours	A²(60*60s)
      49 -> "A²h"
      # mass flux			kilogram per second	kg/s
      50 -> "kg/s"
      # conductance siemens					1/Ω
      51 -> "S, mho"
      # temperature (T)		kelvin
      52 -> "K"
      # R_U²h						(Volt-squared hour meter constant or pulse value)
      53 -> "1/(V²h)"
      # R_I²h						(Ampere-squared hour meter constant or pulse value)
      54 -> "1/(A²h)"
      # R_V, meter constant or pulse value (volume)
      55 -> "1/m³"
      # percentage			%
      56 -> "%"
      # ampere-hours			ampere-hour
      57 -> "Ah"
      # energy per volume					3,6*103 J/m³
      60 -> "Wh/m³"
      # calorific value, wobbe
      61 -> "J/m³"
      # molar fraction of		mole percent		(Basic gas composition unit)
      62 -> "Mol %"
      # mass density, quantity of material			(Gas analysis, accompanying elements)
      63 -> "g/m³"
      # dynamic viscosity pascal second			(Characteristic of gas stream)
      64 -> "Pa s"
      # reserved
      253 -> "(reserved)"
      # other unit
      254 -> "(other)"
      # no unit, unitless, count
      255 -> "(unitless)"
      # UNKNOWN
      _ -> "unknown"
    end
  end

  defp scale(value, scaler) when scaler >= 0 do
    (value * :math.pow(10, scaler))
    |> Float.round(3)
  end
  defp scale(value, scaler) do
    (value * :math.pow(10, scaler))
    |> Float.round(scaler * -1)
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    Enum.map(id_strings(), fn s -> %{field: s, display: s} end)
  end

  def tests() do
    [
      # Test format:
      # {:parse_hex, received_payload_as_hex, meta_map, expected_result},
      {:parse_hex, "03020C0A1EFB000000000EC85CFA0F0A1EFB000000000CF6C960", %{meta: %{frame_port: 15}},
        %{
          "ID_OBIS_1_8_0" => 2480.12026,
          "ID_OBIS_1_8_0_unit" => "Wh",
          "ID_OBIS_2_8_0" => 2175.0,
          "ID_OBIS_2_8_0_unit" => "Wh"
        }
      },
      {:parse_hex, "0301090A090145425A0100BC614E", %{meta: %{frame_port: 15}},
        %{"ID_OBIS_0_0_9" => "1EBZ0112345678"}
      },
      {:parse_hex, "03030C0A1EFB000000000EC85CFA090A090145425A0100BC614E0F0A1EFB000000000CF6C960", %{meta: %{frame_port: 15}},
        %{
          "ID_OBIS_1_8_0" => 2480.12026,
          "ID_OBIS_1_8_0_unit" => "Wh",
          "ID_OBIS_2_8_0" => 2175.0,
          "ID_OBIS_2_8_0_unit" => "Wh",
          "ID_OBIS_0_0_9" => "1EBZ0112345678",
        }
      },
      {:parse_hex, "0301090A090145425A0100BC614E 4203010203", %{meta: %{frame_port: 15}},
        %{"ID_OBIS_0_0_9" => "1EBZ0112345678", "id_66_unknown" => "010203"}
      },
      {:parse_hex, "0301090A090145425A0100BC614E 420301", %{meta: %{frame_port: 15}},
        %{"ID_OBIS_0_0_9" => "1EBZ0112345678", "parsing_rest_error" => "420301"}
      },
    ]
  end
end
