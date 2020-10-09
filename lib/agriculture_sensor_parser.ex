defmodule Parser do
  use Platform.Parsing.Behaviour
  @doc """
     => this is an "@moduledoc"
     # Agriculture Sensor Parser
  
     Build after: T0005978_TRM
     for: Agriculture Sensor
     by: TEKTELIC Communications
     
     Changelog:
       2020-09-29 [fb]: Initial. (without Response to Config/Control Commands)
       2020-10-09 [fb]: 
         - Style changes (using pipes) in recursive "parse_dyn" function, which makes it a bit slimmer. 
         - changed handling of empty bitstrings in the default behaviour of case statement in the "parse_dyn" function.
         - optimized map in "accelerometer_data" and divided it up to a single value per Achsis so: "accelerometer_{x,y,z}"
         - added more test-payloads.
  """
  
  # Does only start if the frame_port matches (thx to elixirs pattern matching)
  def parse(<< data::binary >>, %{meta: %{frame_port: 10}}) do 
    # The recursion thing..
    parse_dyn( Map.new(), data ) # Returns the final List/Map
  end
  
   # Configuration/ Control Commands
  def parse(<< data::binary >>, %{meta: %{frame_port: 100}}) do
    Logger.warn "Configuration/ Control Command received!"
    %{
      configuration_control_commands: data
    }
  end
  
  
  # Catchall o.O
  def parse(_event, _meta) do
    Logger.info "Catchall!"
    []
  end
  
  
# ---
  
  # The dynamic uplink parser
  defp parse_dyn( parsed_payload, << data::binary >> ) do
    # ! REKURSIV !
    # TODO: implement failsafe..
    # _meta should be handled in a higher function eq. parse() => becuase of the recursion
    
    case data do
      # TEMPLATE | x Byte/-s | Fakt: Wrote down some facts to keep in mind.. 
#      << 0x00, 0xFF, dummy::8 , overhead::binary >> ->  
#       parsed_payload
#       |>  Map.put_new(:dummy, dummy) # Adds the "dummy" value to the "parsed_payload" map, because it's added as first parameter and adds the value "dummy" associatet with the atom ":dummy"
#       |>  parse_dyn overhead # Parses on with recursion, passes "parsed_payload" as first parameter and the bitstring <<overhead>> as second (no need for pointy brackets)


      # battery_remaining_lifetime | 1 Byte | Fakt: 1%/LSB
      << 0x00, 0xFF, battery_remaining_lifetime::8 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:battery_remaining_lifetime, battery_remaining_lifetime)
        |>  parse_dyn overhead
        # pass the overhead as second argument

      # input_1 (Soil Moisture) | 2 Bytes | Fakt: 1kHz/LSB
      << 0x01, 0x04, input_1::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:input_1, input_1)
        |>  parse_dyn overhead
     
      
      # input_2 (Soil Temperature) | 2 Bytes | Fakt: 1mV/LSB
      << 0x02, 0x02, input_2::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:input_2, input_2)
        |>  parse_dyn overhead
        
        
      # watermark_01 (Soil Water Tension) | 2 Bytes | Fakt: 1Hz/LSB
      << 0x05, 0x04, watermark_01::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:watermark_01, watermark_01)
        |>  parse_dyn overhead
        
      
      # watermark_02 (Soil Water Tension) | 2 Bytes | Fakt: 1Hz/LSB
      << 0x06, 0x04, watermark_02::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:watermark_02, watermark_02)
        |>  parse_dyn overhead
        
        
      # ambient_light_intensity | 2 Bytes | Fakt: 1lx/LSB
      << 0x09, 0x65, ambient_light_intensity::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:ambient_light_intensity, ambient_light_intensity)
        |>  parse_dyn overhead
        
        
      # 1. ambient_light_alarm [FALSE] | 1 Byte | Fakt: Boolean (0x00 -> No alarm; 0xFF -> ALARM!)
      << 0x09, 0x00, 0x00, overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:parsed_payload, false)
        |>  parse_dyn overhead

      # 2. ambient_light_alarm [TRUE]
      << 0x09, 0x00, 0xFF, overhead::binary >> ->
        parsed_payload
        |>  Map.put_new(:ambient_light_alarm, true)
        |>  parse_dyn overhead
        
        
      # accelerometer_data | 6 Byte | Fakt: 1 milli-g: [1.Byte = X-Data; 2.Byte = Y-Data; 3.Byte = Z-Data]/ Signed (individuall per Achsis) => Integer is signed ^^
      << 0x0A, 0x71, x_achis::integer-size(16), y_achis::integer-size(16), z_achis::integer-size(16), overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:accelerometer_x, x_achis)
        |>  Map.put_new(:accelerometer_y, y_achis)
        |>  Map.put_new(:accelerometer_z, z_achis)
        |>  parse_dyn overhead
        
        
      # impact_magnitude | 2 Byte | Fakt: 1 milli-g
      << 0x0A, 0x02, impact_magnitude::16 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:impact_magnitude, impact_magnitude)
        |>  parse_dyn overhead
        
        
      # 1. impact_alarm [FALSE] | 1 Byte | Fakt: Boolean (0x00 -> No impact alarm; 0xFF -> ALARM!)
      << 0x0A, 0x00, 0x00, overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:impact_alarm, false)
        |>  parse_dyn overhead

      # 2. impact_alarm [TRUE]
      << 0x0A, 0x00, 0xFF, overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:impact_alarm, true)
        |>  parse_dyn overhead
        
        
      # ambient_temperature | 2 Byte | Fakt: 0.1 °C/LSB signed
      << 0x0B, 0x67, ambient_temperature::integer-size(16), overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:ambient_temperature, ambient_temperature * 0.1) # Scaling of ambient temperature
        |>  parse_dyn overhead
        
        
      # ambient_relative_humidity | 1 Byte | Fakt: 0.5%/LSB
      << 0x0B, 0x68, ambient_relative_humidity::8 , overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:ambient_relative_humidity, ambient_relative_humidity * 0.5) # Scaling of ambient relative humidity
        |>  parse_dyn overhead
        
        
      # mcu_temperature | 1 Byte | Fakt: 0.1 °C/LSB signed
      << 0x0C, 0x67, mcu_temperature::integer-size(8), overhead::binary >> ->  
        parsed_payload
        |>  Map.put_new(:mcu_temperature, mcu_temperature * 0.1) # Scaling of mcu temperature
        |>  parse_dyn overhead
        
        
      # Failsafe / Stop point (if no condition fits or data is just empty..)
      << x::binary >> when byte_size(x) > 0 ->
        Logger.error "There is unparsed data left! (#{byte_size(x)} Bytes) - It could be invalid or an parsing error.."
        parsed_payload = Map.put_new(parsed_payload, :configuration_control_commands, "There is unparsed data left! (#{byte_size(x)} Bytes) => (#{Base.encode16(x)})")  # To see in Control/Field
        
        [parsed_payload]
        
      # Default behaviour -> no bytes left
      <<>> -> 
        [parsed_payload] # Returns the payload.. could be empty
    end
  end
  
  
# ---

  
  # Definition of Fields
  def fields() do
    [
      %{
        "field"   =>"battery_remaining_lifetime",
        "unit"    =>"%",
        "display" =>"Batterie (restliche Lebenszeit)"
      },
      %{
        "field"   =>"input_1",
        "unit"    =>"kHz", # no Conversion factor provided
        "display" =>"Bodenfeuchtigkeit"
      },
      %{
        "field"   =>"input_2",
        "unit"    =>"mV", # no Conversion factor provided
        "display" =>"Bodentemperatur"
      },
      %{
        "field"   =>"watermark_01",
        "unit"    =>"Hz", # no Conversion factor provided
        "display" =>"Bodenwasserspannung 1"
      },
      %{
        "field"   =>"watermark_02",
        "unit"    =>"Hz", # no Conversion factor provided
        "display" =>"Bodenwasserspannung 2"
      },
      %{
        "field"   =>"ambient_light_intensity",
        "unit"    =>"lx",
        "display" =>"Umgebungslichtintensität"
      },
      %{
        "field"   =>"ambient_light_alarm",
        "display" =>"Umgebungslichtalarm"
      },
      %{
        "field"   =>"accelerometer_x",
        "unit"    =>"milli-𝑔",
        "display" =>"Beschleunigung X-Achse"
      },
      %{
        "field"   =>"accelerometer_y",
        "unit"    =>"milli-𝑔",
        "display" =>"Beschleunigung Y-Achse"
      },
      %{
        "field"   =>"accelerometer_z",
        "unit"    =>"milli-𝑔",
        "display" =>"Beschleunigung Z-Achse"
      },
      %{
        "field"   =>"impact_magnitude",
        "unit"    =>"milli-𝑔",
        "display" =>"Aufprallgröße"
      },
      %{
        "field"   =>"impact_alarm",
        "display" =>"Aufprallalarm"
      },
      %{
        "field"   =>"ambient_temperature",
        "unit"    =>"°C",
        "display" =>"Umgebungstemperatur"
      },
      %{
        "field"   =>"ambient_relative_humidity",
        "unit"    =>"%",
        "display" =>"relative Luftfeuchtigkeit"
      },
      %{
        "field"   =>"mcu_temperature",
        "unit"    =>"°C",
        "display" =>"MCU Temperatur"
      }
    ]
  end
  
  
  # TEST's
  def tests() do
    # Note: please reorder/cut/add the payload to test dynamic parsing behaviour (in a new element down here 👇)
    [
      { # All in one (ordered by documentation listing)
        :parse_hex, "00FF0001040000020200000504000006040000096500000900000A710000000000000A0200000A00000B6700000B68000C6700", %{meta: %{frame_port: 10}}, %{
          battery_remaining_lifetime: 0,
          input_1: 0,
          input_2: 0,
          watermark_01: 0,
          watermark_02: 0,
          ambient_light_intensity: 0,
          ambient_light_alarm: false,
          accelerometer_data: %{x: 0, y: 0, z: 0},
          impact_magnitude: 0,
          impact_alarm: false,
          ambient_temperature: 0,
          ambient_relative_humidity: 0,
          mcu_temperature: 0
        }
      },
      {
        :parse_hex, "0104057a020202f00965002b0b6700d50b685c", %{meta: %{frame_port: 10}}, %{
          ambient_light_intensity: 43,
          ambient_relative_humidity: 46.0,
          ambient_temperature: 21.3,
          input_1: 1402,
          input_2: 752
        }
      },
      {
        :parse_hex, "0104057a020202d3096500220b6700e20b685b", %{meta: %{frame_port: 10}}, %{
          ambient_light_intensity: 34,
          ambient_relative_humidity: 45.5,
          ambient_temperature: 22.6,
          input_1: 1402,
          input_2: 723
        }
      },
      {
        :parse_hex, "0104056d02020446096503b10b67005a0b68aa", %{meta: %{frame_port: 10}}, %{
          ambient_light_intensity: 945,
          ambient_relative_humidity: 85.0,
          ambient_temperature: 9.0,
          input_1: 1389,
          input_2: 1094
        }
      },
    ]
  end
  
end
