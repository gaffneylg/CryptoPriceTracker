defmodule PoeticoinsWeb.ProductComponent do
  use PoeticoinsWeb, :live_component

  import PoeticoinsWeb.ProductHelpers

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{trade: trade}=_assigns, socket) when not is_nil(trade) do
    product_id = to_string(trade.product)
    event_name = "new_trade:#{product_id}"
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:product_id, product_id)
      |> push_event(event_name, to_event(trade))
    {:ok, socket}
  end

  def update(assigns, socket) do
    product = assigns.id
    socket =
      assign(socket,
        product: product,
        trade: Poeticoins.get_last_trade(product),
        timezone: assigns.timezone)
    {:ok, socket}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~H"""
      <div class="product-component">
        <button class="remove" phx-click="remove-product"
          phx-value-product-id={ "#{to_string(@product)}" }>X</button>
        <div class="currency-container">
          <img class="icon" src={"#{crypto_icon(@socket, @product)}"}/>
          <div class="crypto-name">
            <%= crypto_name(@product) %>
          </div>
        </div>

        <div class="price-container">
          <ul class="currency-symbols">
            <%= for curr <- currency_icons() do %>
              <li class={"#{if currency_symbol(@product) == curr, do: 'active' }"}>
                <%= curr %>
              </li>
            <% end %>
          </ul>

          <div class="price">
            <%= currency_char(@product) %>
            <%= @trade.price %>
          </div>
        </div>

        <div class="chart-component">
          <div phx-hook="Chart"
              id={"product-chart-#{to_string(@product)}"}
              data-product-id={"#{to_string(@product)}"}
              phx-update="ignore">
            <div class="chart-container"></div>
          </div>
        </div>

        <div class="exchange-name">
          <%= @product.exchange_name %>
        </div>

        <div class="trade-time">
          <%= human_datetime(@trade.traded_at, @timezone) %>
        </div>
      </div>
    """
  end

  def render(assigns) do
    ~H"""
      <div class="product-component">
        <div class="currency-container">
          <img class="icon" src={"#{crypto_icon(@socket, @product)}"}/>
          <div class="crypto-name">
            <%= crypto_name(@product) %>
          </div>
        </div>

        <div class="price-container">
          <ul class="currency-symbols">
            <%= for curr <- currency_icons() do %>
              <li class={"#{if currency_symbol(@product) == curr, do: 'active' }"}>
                <%= curr %>
              </li>
            <% end %>
          </ul>

          <div class="price">
            <%= currency_char(@product) %>
            ...
          </div>
        </div>

        <div class="exchange-name">
          <%= @product.exchange_name %>
        </div>

        <div class="trade-time">
        </div>
      </div>
    """
  end

  def to_event(trade) do
    %{
      traded_at: DateTime.to_unix(trade.traded_at, :millisecond),
      price: trade.price,
      volume: trade.volume
    }
  end
end
