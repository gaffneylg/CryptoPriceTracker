defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  # def render(assigns) do
  #   ~L"""
  #   <div class="poeticoins-toolbar">
  #     <div class="title">Crypto Tracker</div>

  #     <form action="#" phx-submit="add-product">
  #       <select name="product_id" class="select-product">

  #         <option selected disabled>Add a Crypto Product</option>

  #         <%= for {exchange_name, products} <- group_products_by_exchange() do %>
  #           <optgroup label="<%= exchange_name %>">
  #             <%= for product <- products do %>
  #               <option value="<%= to_string(product) %>">
  #                 <%= crypto_name(product) %>
  #                 -
  #                 <%= currency_char(product) %>
  #               </option>
  #             <% end %>
  #           </optgroup>
  #         <% end %>
  #       </select>

  #       <button type="submit" phx-disable-with="Loading...">+</button>
  #     </form>
  #   </div>

  #   <div class="product-components">
  #     <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
  #       <div class="product-component">
  #         <div class="currency-container">
  #           <img class="icon" src="<%= crypto_icon(@socket, product) %>" />
  #           <div class="crypto-name">
  #             <%= crypto_name(product) %>
  #           </div>
  #         </div>

  #         <div class="price-container">
  #           <ul class="currency-symbols">
  #             <%= for curr <- currency_icons() do %>
  #               <li class="<%= if currency_symbol(product) == curr, do: "active" %>">
  #                 <%= curr %>
  #               </li>
  #             <% end %>
  #           </ul>

  #           <div class="price">
  #             <%= currency_char(product) %>
  #             <%= trade.price %>
  #           </div>
  #         </div>

  #         <div class="exchange-name">
  #           <%= product.exchange_name %>
  #         </div>

  #         <div class="trade-time">
  #           <%= human_datetime(trade.traded_at) %>
  #         </div>
  #       </div>
  #     <% end %>
  #   </div>
  #   """
  # end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))
    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    [exchange, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange, currency_pair)
    socket = add_product_check(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", %{} = _params, socket) do
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search}, socket) do
    products =
      Poeticoins.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)
      {:noreply, assign(socket, :products, products)}
  end

  defp add_product_check(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
      |> put_flash(:info, "#{product.exchange_name} - #{product.currency_pair} added successfully.")
    else
      socket
      |> put_flash(:error, "The product was already added.")
    end
  end

  def group_products_by_exchange do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)
    socket
    |> update(:products, & &1 ++ [product])
    |> update(:trades, fn trades ->
      trade = Poeticoins.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end
end
