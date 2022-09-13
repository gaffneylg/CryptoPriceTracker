defmodule Poeticoins do
  @moduledoc """
  Poeticoins keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  This is a single module to expose initial functionalities, here it is subscribing to trades.
  Choosing what goes in here is generally whatever makes the code easier to use and maintain.
  If we want to expose some of the functionalities in here, we don't have to rewrite,
  we can use defdelegate to point to functions inside other modules.
  """

  defdelegate subscribe_to_trades(product),
    to: Poeticoins.Exchanges, as: :subscribe

  defdelegate unsubscribe_to_trades(product),
    to: Poeticoins.Exchanges, as: :unsubscribe

  defdelegate get_last_trade(product), to: Poeticoins.Historical
  defdelegate get_last_trades(products), to: Poeticoins.Historical
end
