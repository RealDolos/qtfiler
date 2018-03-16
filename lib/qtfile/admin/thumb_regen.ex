defmodule Qtfile.Admin.ThumbRegen do
  use GenStage
  alias Qtfile.Admin.ControlEvent

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer_consumer, :waiting_for_events,
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

  def handle_info(:trickle_files, {:trickling_files, [], timer}) do
    {:ok, :cancel} = :timer.cancel(timer)
    {:noreply, [], :waiting_for_events}
  end

  def handle_info(:trickle_files, {:trickling_files, files, timer}) do
    {files_to_send, files_to_keep} = Enum.split(files, 32)
    {:noreply, files_to_send, {:trickling_files, files_to_keep, timer}}
  end

  def handle_events(_events, _from, state) do
    files = Qtfile.Files.list_files()
    new_state =
      case state do
        :waiting_for_events ->
          :trickle_files = send(self(), :trickle_files)
          {:ok, timer} = :timer.send_interval(65536, :trickle_files)
          {:trickling_files, files, timer}
        {:trickling_files, current_files, timer} ->
          {:trickling_files, current_files ++ files, timer}
      end
    {:noreply, [], new_state}
  end
end
