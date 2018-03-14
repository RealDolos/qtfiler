defmodule Qtfile.Admin.ControlEvent do
  use GenStage
  alias Okasaki.Implementations.ConstantQueue, as: Queue
  
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:producer, {Queue.empty(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def thumb_regen(timeout \\ 5000) do
    GenStage.call(__MODULE__, :thumb_regen, timeout)
  end

  def handle_call(:thumb_regen, from, {queue, pending_demand}) do
    queue = Queue.insert(queue, {from, :thumb_regen})
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case Queue.remove(queue) do
      {:ok, {{from, event}, queue}} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, [event | events])
      {:error, :empty} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
