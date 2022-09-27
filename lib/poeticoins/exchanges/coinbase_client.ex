defmodule Poeticoins.Exchanges.CoinbaseClient do
  alias Poeticoins.{Exchanges, Product, Trade}
  alias Poeticoins.Exchanges.Client
  require Client

  Client.defclient exchange_name: "Coinbase",
                   host: 'ws-feed.pro.coinbase.com',
                   port: 443,
                   currency_pairs: ["BTC-EUR", "ETH-EUR", "BTC-USD", "ETH-USD"]

  @impl true
  def handle_ws_message(%{"type" => "ticker"}=msg, state) do
    {:ok, trade} = message_to_trade(msg)
    Exchanges.broadcast(trade)
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "Unhandled message:")
    {:noreply, state}
  end

  @impl true
  def subscription_frames(currency_pairs) do
    msg = %{
      "type" => "subscribe",
      "product_ids" => currency_pairs,
      "channels" => ["ticker"]
    } |> Jason.encode!()
    [{:text, msg}]
  end

  @spec message_to_trade(map) :: {:error, any()} | {:ok, Trade.t()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "last_size", "price"]),
      {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"])
    do
      currency_pair = msg["product_id"]
      {:ok,
        Trade.new(
          product: Product.new(exchange_name(), currency_pair),
          price: msg["price"],
          volume: msg["last_size"],
          traded_at: traded_at
        )
      }
    else
      {:error, _reason} = error -> error
    end
  end
end
