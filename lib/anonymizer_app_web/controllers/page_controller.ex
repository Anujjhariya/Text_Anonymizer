defmodule AnonymizerAppWeb.PageController do
  use AnonymizerAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
