defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger


  #
  # Parser for Lobaro Environmental Sensor that will provide pressure, humidity and temperature data.
  #
  # Changelog:
  #   2020-01-23 [as]: Initial implementation according to "https://docs.lobaro.com/lorawan-sensors/environment-lorawan/index.html" as provided by Lobaro


   def parse(<<fw::24, temp::16, vbat::16-signed>>, %{meta: %{frame_port: 1 }}) do
    << major::8, minor::8, patch::8 >> = << fw::24 >>
    %{
      firmware: "#{major}.#{minor}.#{patch}",
      messagetype: "status",
      temperature: temp / 10,
      battery: vbat / 1000
    }
  end
  
  def parse(<<timestamp::40, error_flag::8, humidity::16, temperature::signed-16, pressure::16>>, %{meta: %{frame_port: 2}}) do
   %{
     messagetype: "measurement",
     error: error_flag,
     humidity: humidity/10,
     temperature: temperature/10,
     pressure: pressure/10
   }
   end
  
  # Catchall for reparsing
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end
  
  
  def fields() do
   [
    %{
      field: "firmware",
      display: "Firmware version"
    },
    %{
      field: "messagetype",
      display: "Message type"
    },
    %{
      field: "battery",
      display: "Battery voltage",
      unit: "V"
    },
    %{
      field: "temperature",
      display: "Temperature",
      unit: "°C"
    },
    %{
      field: "humidity",
      display: "Humidity",
      unit: "%rel"
    },
    %{
      field: "pressure",
      display: "Pressure",
      unit: "hPa"
    }
   ]
  end
 
 
 
end
