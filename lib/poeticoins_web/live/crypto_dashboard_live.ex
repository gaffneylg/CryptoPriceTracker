defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view

  def mount(_paramsm, _session, socket) do
    products = Poeticoins.available_products()
    trades =
      products
      |> Poeticoins.get_last_trades()
      |> Enum.reject(&is_nil(&1))               # rejects any nil values
      |> Enum.map(& {&1.product, &1})           # sets the product as the key and value is the trade
      |> Enum.into(%{})                         # injects the new data into an empty map

    if connected?(socket) do
      Enum.each(products, &Poeticoins.subscribe_to_trades(&1))
    end

    socket = assign(socket, trades: trades, products: products)
    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      update(socket, :trades, &Map.put(&1, trade.product, trade))
    {:noreply, socket}
  end
end
