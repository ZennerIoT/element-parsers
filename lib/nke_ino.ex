defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # ELEMENT IoT Parser for NKE Watteco IN'O
  #
  # Link: http://www.nke-watteco.com/product/ino-lora-state-report-and-output-control-sensor/
  # Documentation: http://support.nke-watteco.com/ino
  #
  # This parser tries to be compatible with this online payload parsing utility:
  #   http://support.nke-watteco.com/codec-online/
  #
  # Changelog
  #   2018-09-17 [jb]: Handling missing fctrl, added fields like "input_2_state" for better historgrams.
  #   2018-11-19 [jb]: Renamed fields according to NKE docs, see tests. Added parsing of cmdid, clusterid, attrid, attrtype.
  #


  def parse(<<fctrl::8, cmdid::8, clusterid::16, rest::binary>> = payload, meta) do
    frame_port = get_in(meta, [:meta, :frame_port])
    with {:ok, endpoint} <- fctrl_to_endppoint(fctrl),
         {:ok, cmd} <- parse_cmd(cmdid, clusterid, rest) do
       Map.merge(%{endpoint: endpoint}, cmd)
    else
      error ->
        Logger.warn("NKE Parser with payload #{inspect payload} and frame_port #{inspect frame_port} failed with: #{inspect error}")
        []
    end
  end
  def parse(payload, meta) do
    frame_port = get_in(meta, [:meta, :frame_port])
    Logger.info("NKE Parser with UNKNOWN payload #{inspect payload} and frame_port #{inspect frame_port}")
    []
  end

  # See: http://support.nke-watteco.com/cluster-binary-input/#PresentValue
  def parse_cmd(0x0A, 0x000F, <<0x0055::16, attr::binary>>) do
    with {:ok, {attr_type, attr_value}} <- parse_attribute(attr) do
      {:ok, %{
        report: "Standard",
        commandid: "ReportAttributes",
        clusterid: "BinaryInput",
        attributeid: "PresentValue",
        attributetype: attr_type,
        data: attr_value,
      }}
    end
  end
  def parse_cmd(0x07, 0x000F, <<status::8, _threeMoreIgnoredBytes::binary>>) do
    {:ok, %{
      report: "Standard",
      commandid: "ConfigureReportingResponse",
      clusterid: "BinaryInput",
      attributeid: "PresentValue",
      status: status,
    }}
  end

  # See: http://support.nke-watteco.com/cluster-binary-input/#Count
  def parse_cmd(0x0A, 0x000F, <<0x0402::16, attr::binary>>) do
    with {:ok, {attr_type, attr_value}} <- parse_attribute(attr) do
      {:ok, %{
        report: "Standard",
        commandid: "ReportAttributes",
        clusterid: "BinaryInput",
        attributeid: "Count",
        attributetype: attr_type,
        data: attr_value,
      }}
    end
  end
  def parse_cmd(0x0A, 0x0006, <<0x0000::16, attr::binary>>) do
    with {:ok, {attr_type, attr_value}} <- parse_attribute(attr) do
      {:ok, %{
        report: "Standard",
        commandid: "ReportAttributes",
        clusterid: "OnOff",
        attributeid: "State",
        attributetype: attr_type,
        data: attr_value,
      }}
    end
  end

  # See: http://support.nke-watteco.com/onoff-cluster/#Clustercommands
  def parse_cmd(0x50, 0x0006, data) do
    result = %{
      report: "Standard",
      commandid: "ClusterSpecificCommand",
      clusterid: "OnOff",
    }
    case data do
      <<0>> -> {:ok, Map.merge(result, %{data: 0, commandname: "off"})}
      <<1>> -> {:ok, Map.merge(result, %{data: 1, commandname: "on"})}
      <<2>> -> {:ok, Map.merge(result, %{data: 2, commandname: "toggle"})}
      <<0xF1, seconds>> -> {:ok, Map.merge(result, %{data: seconds, commandname: "pulse"})}
      <<0x50, flag>> -> {:ok, Map.merge(result, %{data: flag, commandname: "desactivate"})}
      _ -> {:error, :invalid_onoff_data}
    end
  end

  def parse_cmd(_cmdid, _clusterid, _rest), do: {:error, :unknown_cmd}


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


  # See: http://support.nke-watteco.com/attribute-data-types/
  # BOOLEAN_TYPE
  def parse_attribute(<<0x10, val::8>>), do: {:ok, {"Boolean", 1 == val}}
  # UINT8_TYPE
  def parse_attribute(<<0x20, val::signed-8>>), do: {:ok, {"UInt8", val}}
  # UINT16_TYPE
  def parse_attribute(<<0x21, val::signed-16>>), do: {:ok, {"UInt16", val}}
  # UINT24_TYPE
  def parse_attribute(<<0x22, val::signed-24>>), do: {:ok, {"UInt24", val}}
  # UINT32_TYPE
  def parse_attribute(<<0x23, val::signed-32>>), do: {:ok, {"UInt32", val}}
  # INT8_TYPE
  def parse_attribute(<<0x28, val::unsigned-8>>), do: {:ok, {"Int8", val}}
  # INT16_TYPE
  def parse_attribute(<<0x29, val::unsigned-16>>), do: {:ok, {"Int8", val}}
  # INT32_TYPE
  def parse_attribute(<<0x2b, val::unsigned-32>>), do: {:ok, {"Int8", val}}
  # TODO: GENERAL8_TYPE
  # TODO: GENERAL16_TYPE
  # TODO: GENERAL24_TYPE
  # TODO: GENERAL32_TYPE
  # TODO: BITMAP8_TYPE
  # TODO: UINT8_ENUM
  # TODO: CHAR_STRING
  # TODO: BYTES_STRING
  # TODO: LONG_BYTES_STRING
  # TODO: STRUCTURE_ORDEREDSEQUENCE
  # TODO: SINGLE_TYPE
  # Error
  def parse_attribute(_), do: {:error, :unknown_attribute}


  def tests() do
    [
      {
        :parse_hex, "1150000601", %{},
        %{
          clusterid: "OnOff",
          commandid: "ClusterSpecificCommand",
          data: 1,
          commandname: "on",
          endpoint: 0,
          report: "Standard"
        } # Endpoint 0 was switched on (data=1)
      },
      {
        :parse_hex, "110A000F04022300000003", %{},
        %{
          attributeid: "Count",
          attributetype: "UInt32",
          clusterid: "BinaryInput",
          commandid: "ReportAttributes",
          data: 3,
          endpoint: 0,
          report: "Standard"
        } # Endpoint 0 has a input counter of 3 (data=3)
      },
      {
        :parse_hex, "310A000F00551000", %{},
        %{
          attributeid: "PresentValue",
          attributetype: "Boolean",
          clusterid: "BinaryInput",
          commandid: "ReportAttributes",
          data: false,
          endpoint: 1,
          report: "Standard"
        } # Endpoint 1 input state currently off (data=false)
      },
      {
        :parse_hex, "5107000F00000055", %{},
        %{
          attributeid: "PresentValue",
          clusterid: "BinaryInput",
          commandid: "ConfigureReportingResponse",
          endpoint: 2,
          report: "Standard",
          status: 0,
        } # Endpoint 2 accepted configuration (because of status=0)
      },
      {
        :parse_hex, "110A000600001000", %{},
        %{
          attributeid: "State",
          attributetype: "Boolean",
          clusterid: "OnOff",
          commandid: "ReportAttributes",
          data: false,
          endpoint: 0,
          report: "Standard"
        } # Endpoint 0 relay state off (date=false)
      },
      {
        :parse_hex, "110A000600001001", %{},
        %{
          attributeid: "State",
          attributetype: "Boolean",
          clusterid: "OnOff",
          commandid: "ReportAttributes",
          data: true,
          endpoint: 0,
          report: "Standard"
        } # Endpoint 0 relay state on (date=true)
      },
      {
        :parse_hex, "110A000F00551000", %{},
        %{
          attributeid: "PresentValue",
          attributetype: "Boolean",
          clusterid: "BinaryInput",
          commandid: "ReportAttributes",
          data: false,
          endpoint: 0,
          report: "Standard"
        } # Endpoint 0 input state currently off (data=false)
      },
    ]
  end
end
