defmodule Qtfile.Admin.ThumbRegen do
  use GenStage
  alias Qtfile.Admin.ControlEvent
  require Logger

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, {},
     dispatcher: GenStage.BroadcastDispatcher,
     subscribe_to: [{ControlEvent, selector: &tag_selector/1}],
    }
  end

  defp tag_selector(:thumb_regen) do
    true
  end

  defp tag_selector(_) do
    false
  end

  def handle_events(_events, _from, {}) do
    files = Qtfile.Files.list_files()
    {:noreply, files, {}}
  end
end
