defmodule Parser do
  use Platform.Parsing.Behaviour

  # Parser for DZG devices using the v1.0 LoRaWAN Frame Format from file "LoRaWAN Frame Format 1.0_181218.pdf".
  #
  # Changelog
  #   2018-xx-xx [jb]: Initial version.
  #   2019-06-20 [jb]: Added medium "heatcostallocator".

  # Test hex payload: "51BBF1BD0228000000"
  def parse(<<header::8, meterid::integer-little-32, register_value::integer-little-32>>, _meta) do
  << _version::integer-little-2, medium::integer-little-3,qualifier::integer-little-3 >> = <<header::8>>

    {medium_name, scaler} = case medium do
      0 -> {"heatcostallocator", 0}
      1 -> {"temperature", 0.01}
      2 -> {"electricity", 0.01}
      3 -> {"gas", 0.01}
      4 -> {"heat", 0.01}
      6 -> {"hotwater", 0.01}
      7 -> {"water", 0.01}
      _ -> {"unknown", 1}
    end

    %{
      qualifier: qualifier,
      meterid: meterid,
      medium: medium_name,
      register: register_value * scaler,
    }
  end

  def fields do
    [
      %{
        "field" => "register",
        "display" => "Register",
      },
      %{
        "field" => "qualifier",
        "display" => "Qualifier",
      },
      %{
        "field" => "medium",
        "display" => "Medium"
      },
      %{
        "field" => "meterid",
        "display" => "MeterID"
      }
    ]
  end

  def tests() do
    [
      {
        :parse_hex, "51D0F1BD0263000000", %{}, %{
          qualifier: 1,
          meterid: 46002640,
          medium: "electricity",
          register: 0.99
        }
      },
      {
        :parse_hex, "51294BBC000D000000", %{},  %{
          medium: "electricity",
          meterid: 12340009,
          qualifier: 1,
          register: 0.13
        }
      },

      # Heat cost allocator

      {
        :parse_hex, "41294BBC000D000000", %{},  %{medium: "heatcostallocator", meterid: 12340009, qualifier: 1, register: 0}
      },
    ]
  end
end
