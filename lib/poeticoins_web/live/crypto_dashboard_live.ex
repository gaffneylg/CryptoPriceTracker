defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  def mount(_paramsm, _session, socket) do
    # products = Poeticoins.available_products()
    # trades =
    #   products
    #   |> Poeticoins.get_last_trades()
    #   |> Enum.reject(&is_nil(&1))               # rejects any nil values
    #   |> Enum.map(& {&1.product, &1})           # sets the product as the key and value is the trade
    #   |> Enum.into(%{})                         # injects the new data into an empty map

    # if connected?(socket) do
    #   Enum.each(products, &Poeticoins.subscribe_to_trades(&1))
    # end

    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <form action="#" phx-submit="add-product">
        <select name="product_id">
          <option selected disabled>Add a Crypto Product</option>
          <%= for product <- Poeticoins.available_products() do %>
            <option value="<%= to_string(product) %>">
              <%= product.exchange_name %> - <%= product.currency_pair %>
            </option>
          <% end %>
        </select>

        <button type="submit" phx-disable-with="Loading...">Add Product</button>
      </form>

      <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
        <div class="product-component">
          <div class="currency-container">
            <div class="crypto-name">
              <%= product.currency_pair %>
            </div>
          </div>

          <div class="price-container">
            <div class="price">
              <%= trade.price %>
            </div>
          </div>

          <div class="exchange-name">
            <%= product.exchange_name %>
          </div>

          <div class="trade-time">
            <%= trade.traded_at %>
          </div>

        </div>
      <% end %>


    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      update(socket, :trades, &Map.put(&1, trade.product, trade))
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
