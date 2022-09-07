defmodule Poeticoins.Exchanges.BitstampClient do
  alias Poeticoins.{Product, Trade}
  alias Poeticoins.Exchanges.Client
  require Client

  Client.defclient exchange_name: "Bitstamp",
                   host: 'ws.bitstamp.net',
                   port: 443,
                   currency_pairs: ["btceur", "etheur", "btcusd", "ethusd"]

  @impl true
  def handle_ws_message(%{"event" => "trade"}=msg, state) do
    trade = message_to_trade(msg)
    IO.inspect(trade, label: "Bitstamp trade")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "Unhandled message:")
    {:noreply, state}
  end

  @impl true
  def subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame/1)
  end

  def subscription_frame(currency_pair) do
    msg = %{
      "event" => "bts:subscribe",
      "data" => %{
        "channel" => "live_trades_#{currency_pair}"
      }
    } |> Jason.encode!()
    {:text, msg}
  end

  @spec message_to_trade(map) :: {:error, any()} | Poeticoins.Trade.t()
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair}=_msg)
    when is_map(data)
  do
    with :ok <- validate_required(data, ["amount_str", "timestamp", "price_str"]),
      {:ok, traded_at} <- timestamp_to_datetime(data["timestamp"])
    do
      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: data["price_str"],
        volume: data["amount_str"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

  def message_to_trade(_msg), do: {:error, :invalid_trade_message}

  @spec timestamp_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  def timestamp_to_datetime(ts) do
    case Integer.parse(ts) do
      {ts_int, _} ->
        DateTime.from_unix(ts_int)
      :error ->
        {:error, "Invalid timestamp string"}
    end
  end
end
