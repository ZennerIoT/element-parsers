defmodule Parser do
  use Platform.Parsing.Behaviour
  require Logger

  # Parser for Axioma Metering - ULTRASONIC WATER METER QALCOSONIC W1
  # Lora Payload (Long) “Extended”

  # Changelog:
  #   2020-02-04 [jb]: Initial implementation according to "Axioma Lora Payload W1 V01.7 Extended.pdf"

  # Alarm
  def parse(<<current_unix::32-little, status::8>>, %{meta: %{frame_port: 103}}) do
    %{
      type: :alarm,
      timestamp: unix_to_iso(current_unix),
    } |> add_status_alarm(status)
  end

  # Configuration
  def parse(<<_payload::binary>>, %{meta: %{frame_port: 101}}) do
    %{
      type: :config,
      # Not parsing payload, because documentation is completely wrong.
    }
  end

  # Current and historical values
  def parse(<<current_unix::32-little, status::8, current_volume::32-little, log_unix::32-little, log_volume::32-little, rest::binary>>, %{meta: %{frame_port: 100}}) do

    log_unix = log_unix - rem(log_unix, 3600) # Make full hours

    current_volume = make_m3(current_volume)
    log_volume = make_m3(log_volume)

    [{log_unix, log_volume}]
    |> parse_period(rest)
    |> Kernel.++([{current_unix, current_volume}])
    |> Enum.map(fn({unix, volume}) ->
      {
        %{
          type: :volume,
          volume: volume,
          timestamp: unix_to_iso(unix),
        } |> add_status(status),
        [measured_at: DateTime.from_unix!(unix)]
      }
    end)
  end

  def parse(payload, meta) do
    Logger.warn("Could not parse payload #{inspect payload} with frame_port #{inspect get_in(meta, [:meta, :frame_port])}")
    []
  end

  #------------

  defp make_m3(x), do: x * 0.001

  defp unix_to_iso(unix), do: unix |> DateTime.from_unix!() |> DateTime.to_iso8601()

  defp add_status_alarm(row, status) do
    errors = status_to_alarms(status)
    error = if errors == [], do: 0, else: 1
    errors_string = Enum.join(errors, ",")

    Map.merge(row, %{
      error: error,
      errors: errors_string,
    })
  end

  defp status_to_alarms(status) do
    use Bitwise
    [
      leakage:          Bitwise.band(status, 0b00000001),
      burst:            Bitwise.band(status, 0b00000010),
      freeze:           Bitwise.band(status, 0b00000100),
      tamper:           Bitwise.band(status, 0b00001000),
      no_consumption:   Bitwise.band(status, 0b00010000),
      backflow:         Bitwise.band(status, 0b00100000),
    ]
    |> Enum.filter(fn
      ({_error, 0}) -> false
      ({_error, _}) -> true
    end)
    |> Keyword.keys
  end


  defp add_status(row, status) do
    errors = status_to_errors(status)
    error = if errors == [], do: 0, else: 1
    errors_string = Enum.join(errors, ",")

    Map.merge(row, %{
      error: error,
      errors: errors_string,
    })
  end

  defp status_to_errors(status) do
    use Bitwise
    [
      power_low: Bitwise.band(status, 0x04),
      permanent_error: Bitwise.band(status, 0x08),
      dry_or_temporary_error: Bitwise.band(status, 0x10),
    ]
    |> status_temp_errors(<<status>>)
    |> Enum.filter(fn
      ({_error, 0}) -> false
      ({_error, _}) -> true
    end)
    |> Keyword.keys
  end

  defp status_temp_errors(acc, <<0b100::3, _::bits>>), do: [{:freeze, 1} | acc]
  defp status_temp_errors(acc, <<0b001::3, _::bits>>), do: [{:leakage, 1} | acc]
  defp status_temp_errors(acc, <<0b101::3, _::bits>>), do: [{:burst, 1} | acc]
  defp status_temp_errors(acc, <<0b011::3, _::bits>>), do: [{:backflow, 1}  | acc]
  defp status_temp_errors(acc, _), do: acc

  defp parse_period([{timestamp, volume}|_] = acc, <<delta::16-little, rest::binary>>) do
    parse_period([{timestamp + 3600, volume + make_m3(delta)}|acc], rest)
  end
  defp parse_period(acc, <<0x2F, _rest::binary>>), do: Enum.reverse(acc) # Handle padding bytes
  defp parse_period(acc, <<>>), do: Enum.reverse(acc) # Binary just ended
  defp parse_period(acc, other) do
    Logger.info("Unexpected binary suffix: #{inspect other}")
    Enum.reverse(acc)
  end

  # Define fields with human readable name and a SI unit if available.
  def fields() do
    [
      # The first field should be a numeric value, so it can be used for graphs.
      %{
        field: "volume",
        display: "Volume",
        unit: "m3",
      },
      %{
        field: "type",
        display: "Type",
      },
      %{
        field: "error",
        display: "Error?",
      },
      %{
        field: "errors",
        display: "Errors",
      },
    ]
  end

  def tests() do
    [
      # Decoding extended structure packet with 15 historical values. (Port 100)
      {:parse_hex, "0ea0355d 30 29350000 54c0345d e7290000 b800b900b800b800b800b900b800b800b800b800b800b800b900b900b900", %{meta: %{frame_port: 100}, transceived_at: test_datetime("2019-01-01T12:34:56Z")},
        [
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-21T19:00:00Z",
              type: :volume,
              volume: 10.727
            },
            [measured_at: test_datetime("2019-07-21 19:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-21T20:00:00Z",
              type: :volume,
              volume: 10.911
            },
            [measured_at: test_datetime("2019-07-21 20:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-21T21:00:00Z",
              type: :volume,
              volume: 11.096
            },
            [measured_at: test_datetime("2019-07-21 21:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-21T22:00:00Z",
              type: :volume,
              volume: 11.28
            },
            [measured_at: test_datetime("2019-07-21 22:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-21T23:00:00Z",
              type: :volume,
              volume: 11.463999999999999
            },
            [measured_at: test_datetime("2019-07-21 23:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T00:00:00Z",
              type: :volume,
              volume: 11.647999999999998
            },
            [measured_at: test_datetime("2019-07-22 00:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T01:00:00Z",
              type: :volume,
              volume: 11.832999999999998
            },
            [measured_at: test_datetime("2019-07-22 01:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T02:00:00Z",
              type: :volume,
              volume: 12.016999999999998
            },
            [measured_at: test_datetime("2019-07-22 02:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T03:00:00Z",
              type: :volume,
              volume: 12.200999999999997
            },
            [measured_at: test_datetime("2019-07-22 03:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T04:00:00Z",
              type: :volume,
              volume: 12.384999999999996
            },
            [measured_at: test_datetime("2019-07-22 04:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T05:00:00Z",
              type: :volume,
              volume: 12.568999999999996
            },
            [measured_at: test_datetime("2019-07-22 05:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T06:00:00Z",
              type: :volume,
              volume: 12.752999999999995
            },
            [measured_at: test_datetime("2019-07-22 06:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T07:00:00Z",
              type: :volume,
              volume: 12.936999999999994
            },
            [measured_at: test_datetime("2019-07-22 07:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T08:00:00Z",
              type: :volume,
              volume: 13.121999999999995
            },
            [measured_at: test_datetime("2019-07-22 08:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T09:00:00Z",
              type: :volume,
              volume: 13.306999999999995
            },
            [measured_at: test_datetime("2019-07-22 09:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T10:00:00Z",
              type: :volume,
              volume: 13.491999999999996
            },
            [measured_at: test_datetime("2019-07-22 10:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "leakage,dry_or_temporary_error",
              timestamp: "2019-07-22T11:37:50Z",
              type: :volume,
              volume: 13.609
            },
            [measured_at: test_datetime("2019-07-22 11:37:50Z")]
          }
                                                                                                     ]
      },
      # Configuration packet
      {:parse_hex, "04FF891331FD17041344FF891344134D931E206201", %{meta: %{frame_port: 101}},
        %{type: :config}
      },
      # Decoding alarm packet (Port 103)
      {:parse_hex, "43b1315d30", %{meta: %{frame_port: 103}},
        %{
          error: 1,
          errors: "no_consumption,backflow",
          timestamp: "2019-07-19T12:02:11Z",
          type: :alarm
        }
      },

      # Real packet from 00070900004D6907
      {:parse_hex, "41643A5E1077010000F086395E77010000000000000000000000000000000000000000000000000000000000000000", %{meta: %{frame_port: 100}},
        [
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T15:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 15:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T16:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 16:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T17:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 17:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T18:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 18:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T19:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 19:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T20:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 20:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T21:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 21:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T22:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 22:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-04T23:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-04 23:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T00:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 00:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T01:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 01:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T02:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 02:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T03:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 03:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T04:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 04:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T05:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 05:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T06:00:00Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 06:00:00Z")]
          },
          {
            %{
              error: 1,
              errors: "dry_or_temporary_error",
              timestamp: "2020-02-05T06:44:17Z",
              type: :volume,
              volume: 0.375
            },
            [measured_at: test_datetime("2020-02-05 06:44:17Z")]
          }
        ]
      },

    ]
  end

  # Helper for testing
  defp test_datetime(iso8601) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso8601)
    datetime
  end

end
