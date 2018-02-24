defmodule QtfileWeb.AdminView do
  use QtfileWeb, :view
  import Qtfile.Settings

  def settings do
    list_settings()
  end
end
