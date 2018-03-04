defmodule Qtfile.FileProcessing.Hashing do
  def initialise_hash() do
    :crypto.hash_init(:sha)
  end

  def update_hash(hash, data) do
    :crypto.hash_update(hash, data)
  end

  def finalise_hash(hash) do
    Base.encode16(:crypto.hash_final(hash), case: :lower)
  end
end
