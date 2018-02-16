defmodule Qtfile.Util do
  def get_ip_address(%{remote_ip: ip}) do
    Qtfile.IPAddressObfuscation.normalise_ip_address(ip)
  end

  def mapSequence(list, mapping) do
    List.foldr(list, {:ok, []}, fn(x, exs) ->
      case {mapping.(x), exs} do
        {{:ok, x}, {:ok, xs}} -> {:ok, [x | xs]}
        _ -> :error
      end
    end)
  end
end
