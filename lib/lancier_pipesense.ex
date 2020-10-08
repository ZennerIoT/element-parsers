defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  #
  # Parser for device Lancier Pipesense that will measure Fernwärme.
  #
  # Changelog:
  #   2020-10-06 [jb]: Initial implementation according to "PipeSensLora payload vorab.pdf"
  #


  def parse(<<common::binary-14, optional::binary-3, errors::binary-4>>, %{meta: %{frame_port: 1}}) do
    %{}
    |> Map.merge(parse_common(common))
    |> Map.merge(parse_optional(optional))
    |> Map.merge(parse_errors(errors))
  end
  def parse(<<common::binary-14, optional::binary-3>>, %{meta: %{frame_port: 10}}) do
    %{}
    |> Map.merge(parse_common(common))
    |> Map.merge(parse_optional(optional))
  end
  def parse(<<common::binary-14>>, %{meta: %{frame_port: 15}}) do
    %{}
    |> Map.merge(parse_common(common))
  end
  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  defp parse_common(<<unix_timestamp::32, iso1::16, loop1::16, iso2::16, loop2::16, bat::16>>) do
    %{
      meas_timestamp: unix_timestamp |> DateTime.from_unix!() |> DateTime.to_iso8601(),

      iso1: iso1,
      loop1: loop1,

      iso2: iso2,
      loop2: loop2,

      battery: bat/1000,
    }
  end
  defp parse_common(data) do
    %{
      common_invalid: 1,
      common_data: Base.encode16(data)
    }
  end

  defp parse_optional(<<temp::16-signed, contact::binary-1>>) do
    <<_::6, contact2::1, contact1::1>> = contact
    %{
      temp: temp,

      contact1: contact1,
      contact1_state: contact_state(contact1),
      contact2: contact2,
      contact2_state: contact_state(contact2),
    }
  end
  defp parse_optional(data) do
    %{
      optional_invalid: 1,
      optional_data: Base.encode16(data)
    }
  end

  defp parse_errors(<<error1::8, error2::binary-1, error3::binary-1, error4::binary-1>>) do

    <<_::5, erde::1, battery::1, history_write::1>> = error2
    <<modem_join::1, modem_send::1, modem_invalid_key::1, mess_thread::1, mess_thread_start::1, eeprom_read::1, eeprom_write::1, history_read::1>> = error3
    <<modem_get_upctr::1, modem_set_upctr::1, modem_invalid_len::1, modem_invalid_param::1, modem_no_channel_free::1, modem_frame_counter::1, modem_input::1, modem_busy_error::1>> = error4

    %{}
    |> Map.merge(case error1 do
      0 -> %{}
      _ -> %{byte_17_error: error1}
    end)

    |> add_error(erde, :erde)
    |> add_error(battery, :battery)
    |> add_error(history_write, :history_write)

    |> add_error(modem_join, :error_modem_join)
    |> add_error(modem_send, :error_modem_send)
    |> add_error(modem_invalid_key, :error_modem_invalid_key)
    |> add_error(mess_thread, :error_mess_thread)
    |> add_error(mess_thread_start, :error_mess_thread_start)
    |> add_error(eeprom_read, :error_eeprom_read)
    |> add_error(eeprom_write, :error_eeprom_write)
    |> add_error(history_read, :error_history_read)

    |> add_error(modem_get_upctr, :error_modem_get_upctr)
    |> add_error(modem_set_upctr, :error_modem_set_upctr)
    |> add_error(modem_invalid_len, :error_modem_invalid_len)
    |> add_error(modem_invalid_param, :error_modem_invalid_param)
    |> add_error(modem_no_channel_free, :error_modem_no_channel_free)
    |> add_error(modem_frame_counter, :error_modem_frame_counter)
    |> add_error(modem_input, :error_modem_input)
    |> add_error(modem_busy_error, :error_modem_busy_error)
  end
  defp parse_errors(data) do
    %{
      errors_invalid: 1,
      errors_data: Base.encode16(data)
    }
  end

  defp add_error(row, 0, _name) do
    row
  end
  defp add_error(row, value, name) do
    Map.merge(row, %{name => value})
  end

  defp contact_state(0), do: :closed
  defp contact_state(1), do: :open

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      %{
        field: "iso1",
        display: "Iso1",
        unit: "kOhm",
      },
      %{
        field: "loop1",
        display: "Loop1",
        unit: "Ohm",
      },

      %{
        field: "iso2",
        display: "Iso2",
        unit: "kOhm",
      },
      %{
        field: "loop2",
        display: "Loop2",
        unit: "Ohm",
      },

      %{
        field: "meas_timestamp",
        display: "MEAS-Timestamp"
      },

      %{
        field: "battery",
        display: "Battery",
        unit: "V",
      },

      %{
        field: "temp",
        display: "Temperature",
        unit: "C",
      },

      %{
        field: "contact1",
        display: "Contact1",
      },
      %{
        field: "contact2",
        display: "Contact2",
      },
    ]
  end

  def tests() do
    [
      {
        :parse_hex,
        "5F7C07ED0DE4044E0DF303F60DB200240F00000000",
        %{meta: %{frame_port: 1}},
        %{
          battery: 3.506,
          contact1: 1,
          contact1_state: :open,
          contact2: 1,
          contact2_state: :open,
          iso1: 3556,
          iso2: 3571,
          loop1: 1102,
          loop2: 1014,
          meas_timestamp: "2020-10-06T06:00:13Z",
          temp: 36
        }
      },

      {
        :parse_hex,
        "5F7C07ED0DE4044E0DF303F60DB200240F",
        %{meta: %{frame_port: 10}},
        %{
          battery: 3.506,
          contact1: 1,
          contact1_state: :open,
          contact2: 1,
          contact2_state: :open,
          iso1: 3556,
          iso2: 3571,
          loop1: 1102,
          loop2: 1014,
          meas_timestamp: "2020-10-06T06:00:13Z",
          temp: 36
        }
      },

      {
        :parse_hex,
        "5F7C07ED0DE4044E0DF303F60DB2",
        %{meta: %{frame_port: 15}},
        %{
          battery: 3.506,
          iso1: 3556,
          iso2: 3571,
          loop1: 1102,
          loop2: 1014,
          meas_timestamp: "2020-10-06T06:00:13Z"
        }
      },
    ]
  end
end
