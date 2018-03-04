defmodule Qtfile.FileProcessing.UploadState do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:put, k, v}, _from, state) do
    {:reply, :ok, Map.put(state, k, v)}
  end

  def handle_call({:get, k}, _from, state) do
    {:reply, Map.fetch(state, k), state}
  end

  def handle_call({:delete, k}, _from, state) do
    {:reply, :ok, Map.delete(state, k)}
  end

  def put(k, v) do
    GenServer.call(__MODULE__, {:put, k, v})
  end

  def get(k) do
    GenServer.call(__MODULE__, {:get, k})
  end

  def delete(k) do
    GenServer.call(__MODULE__, {:delete, k})
  end
end
