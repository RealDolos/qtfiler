defmodule Qtfile.Admin.Supervisor do
  use Supervisor
  alias Qtfile.Admin.{
    ControlEvent,
    ThumbRegen,
  }

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      ControlEvent,
      ThumbRegen,
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
