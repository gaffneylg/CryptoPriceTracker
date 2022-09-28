defmodule PoeticoinsWeb.ProductHelpers do

  alias PoeticoinsWeb.Router.Helpers, as: Routes

  def currency_icons do
    ["eur", "usd"]
  end

  def human_datetime(datetime, timezone \\ "UTC") do
    datetime
    |> DateTime.shift_zone!(timezone)
    Calendar.strftime(datetime, "%b %d %Y, %H:%M:%S")
  end

  def crypto_icon(conn, product) do
    crypto_symbol = crypto_symbol(product)
    relative_path = Path.join("/images/cryptos", "#{crypto_symbol}.svg")
    Routes.static_path(conn, relative_path)
  end

  def crypto_name(product) do
    case crypto_and_currency_symbols(product) do
      %{crypto_symbol: "btc"} -> "Bitcoin"
      %{crypto_symbol: "eth"} -> "Ethereum"
    end
  end

  def currency_char(product) do
    case crypto_and_currency_symbols(product) do
      %{currency_symbol: "usd"} -> "$"
      %{currency_symbol: "eur"} -> "€"
    end
  end

  def currency_symbol(product),
    do: crypto_and_currency_symbols(product).currency_symbol

  def crypto_symbol(product),
    do: crypto_and_currency_symbols(product).crypto_symbol


  defp crypto_and_currency_symbols(%{exchange_name: "Coinbase"} = product) do
    [crypto_symbol, currency_symbol] =
      product.currency_pair
      |> String.split("-")
      |> Enum.map(&String.downcase/1)

      %{crypto_symbol: crypto_symbol, currency_symbol: currency_symbol}
  end

  defp crypto_and_currency_symbols(%{exchange_name: "Bitstamp"} = product) do
    crypto_symbol = String.slice(product.currency_pair, 0..2)
    currency_symbol = String.slice(product.currency_pair, 3..6)
    %{crypto_symbol: crypto_symbol, currency_symbol: currency_symbol}
  end
end
