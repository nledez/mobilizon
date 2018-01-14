defmodule EventosWeb.UserSessionView do
  @moduledoc """
  View for user Sessions
  """
  use EventosWeb, :view

  def render("token.json", %{token: token, user: user}) do
    %{token: token, user: render_one(user, EventosWeb.UserView, "user_simple.json")}
  end
end
