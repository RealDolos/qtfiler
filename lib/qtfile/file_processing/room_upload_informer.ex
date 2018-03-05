defmodule Qtfile.FileProcessing.RoomUploadInformer do
  use GenStage
  alias Qtfile.FileProcessing.UploadEvent

  def start_link(max_demand) do
    GenStage.start_link(__MODULE__, [max_demand], name: __MODULE__)
  end

  def init([max_demand]) do
    {:consumer, {}, subscribe_to:
     [
       {UploadEvent, max_demand: max_demand}
     ]
    }
  end

  def handle_events(files, _from, state) do
    Enum.map(files, fn(file) ->
      processed_file = Qtfile.Files.process_for_browser(file)
      QtfileWeb.RoomChannel.broadcast_new_files([processed_file], file.location.room_id)
    end)

    {:noreply, [], state}
  end
end
