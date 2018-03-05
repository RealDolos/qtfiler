defmodule Qtfile.FileProcessing.UploadEvent do
  use GenStage
  alias Okasaki.Implementations.ConstantQueue, as: Queue
  
  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:producer, {Queue.empty(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def notify_upload(file, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:uploaded, file}, timeout)
  end

  def handle_call({:uploaded, file}, from, {queue, pending_demand}) do
    queue = Queue.insert(queue, {from, file})
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, files) do
    {:noreply, Enum.reverse(files), {queue, 0}}
  end

  defp dispatch_events(queue, demand, files) do
    case Queue.remove(queue) do
      {:ok, {{from, file}, queue}} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, [file | files])
      {:error, :empty} ->
        {:noreply, Enum.reverse(files), {queue, demand}}
    end
  end
end
