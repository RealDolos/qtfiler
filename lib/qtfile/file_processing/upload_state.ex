defmodule Qtfile.FileProcessing.UploadState do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, {})
  end

  def init({}) do
    {:ok, %{}}
  end

  def handle_call({:put, k, v}, _from, state) do
    {:reply, :ok, Map.put(state, k, v)}
  end

  def handle_call({:get, k}, _from, state) do
    {:reply, Map.fetch(state, k), state}
  end
end
