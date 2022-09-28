defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket,
     products: [],
     timezone: get_timezone_from_conn(socket))
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="poeticoins-toolbar">
      <div class="title">Crypto Tracker</div>

      <form action="#" phx-submit="add-product">
        <select name="product_id" class="select-product">

          <option selected disabled>Add a Crypto Product</option>

          <%= for {exchange_name, products} <- group_products_by_exchange() do %>
            <optgroup label={"#{exchange_name}"}>
              <%= for product <- products do %>
                <option value={ "#{to_string(product)}" }>
                  <%= crypto_name(product) %>
                  -
                  <%= currency_char(product) %>
                </option>
              <% end %>
            </optgroup>
          <% end %>
        </select>

        <button type="submit">+</button>
      </form>
    </div>

    <div class="product-components-container">
      <%= for product <- @products do %>
        <%= live_component(PoeticoinsWeb.ProductComponent,
              id: product, timezone: @timezone) %>
      <% end %>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(PoeticoinsWeb.ProductComponent, id: trade.product, trade: trade)
    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
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

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, &List.delete(&1, product))
    {:noreply, socket}
  end

  defp add_product_check(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
    else
      socket
    end
  end

  defp product_from_string(product_id) do
    [exchange, currency_pair] = String.split(product_id, ":")
    Product.new(exchange, currency_pair)
  end

  def group_products_by_exchange do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)
    socket
    |> update(:products, & &1 ++ [product])
  end

  defp get_timezone_from_conn(socket) do
    case get_connect_params(socket) do
      %{"timezone" => timezone} when not is_nil(timezone) -> timezone
      _ -> "UTC"
    end
  end
end
