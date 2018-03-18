defmodule Qtfile.FileProcessing.RoomPreviewInformer do
  use GenStage
  alias Qtfile.FileProcessing.{Thumbnailer, VideoPreviewGenerator}

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:consumer, {},
     subscribe_to: [Thumbnailer, VideoPreviewGenerator],
    }
  end

  def handle_events(previews, _from, state) do
    Enum.map(previews, &QtfileWeb.RoomChannel.broadcast_new_preview/1)
    {:noreply, [], state}
  end
end
