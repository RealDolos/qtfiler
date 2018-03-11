defmodule Qtfile.FileProcessing.RoomMetadataInformer do
  use GenStage
  alias Qtfile.FileProcessing.MetadataGenerator

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:consumer, {},
     subscribe_to: [MetadataGenerator],
    }
  end

  def handle_events(tagged_metadata_objects, _from, state) do
    Enum.map(tagged_metadata_objects, fn({_, _, metadata_object}) ->
      QtfileWeb.RoomChannel.broadcast_new_metadata(
        metadata_object.data, metadata_object.file, metadata_object.file.location.room_id
      )
    end)

    {:noreply, [], state}
  end
end
