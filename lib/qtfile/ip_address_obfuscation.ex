defmodule Qtfile.IPAddressObfuscation do
  import Bitwise

  def ip_filter(room, user, %{ip_address: ip_address} = data) do
    case user.role do
      "admin" -> %{data | ip_address: human_readable(
                    denormalise_ip_address(ip_address))}
      "mod" -> %{data | ip_address: encrypt_ip_address(ip_address, user.secret)}
      "user" -> if room.owner_id == user.id do
        %{data | ip_address:
          encrypt_ip_address(ip_address, :crypto.exor(user.secret, room.secret))
        }
      else
          Map.delete(data, :ip_address)
      end
    end
  end

  def ban_filter(room, user, ip_address) do
    case user.role do
      "admin" -> {:ok, ip_address}
      "mod" -> decrypt_ip_address(ip_address, user.secret)
      "user" -> if room.owner_id == user.id do
        decrypt_ip_address(ip_address, :crypto.exor(user.secret, room.secret))
      else
        {:error, :insufficient_ip_decryption_permission}
      end
    end
  end

  def human_readable(ip_address)

  def human_readable({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  def human_readable({a, b, c, d, e, f, g, h}) do
    [a, b, c, d, e, f, g, h] = Enum.map([a, b, c, d, e, f, g, h], fn(chunk) ->
      Base.encode16(<<chunk::16>>)
    end)
    "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
  end

  defp encrypt_ip_address(ip_address, iv) do
    pt = ip_address
    key = get_secret_key_base()
    {ct, mac} = :crypto.block_encrypt(:aes_gcm, key, iv, {iv, pt, 16})
    result = ct <> mac
    Base.url_encode64(result)
  end

  defp decrypt_ip_address(encrypted_ip_address, iv) do
    key = get_secret_key_base()
    <<ct::128, mac::128>> = Base.url_decode64!(encrypted_ip_address)
    case :crypto.block_decrypt(:aes_gcm, key, iv, {iv, <<ct::128>>, <<mac::128>>}) do
      :error -> {:error, :ip_decryption_failed}
      pt -> {:ok, pt}
    end
  end

  def normalise_ip_address(ip_address)

  def normalise_ip_address({a, b, c, d}) do
    <<d::8, c::8, b::8, a::8, 0::96>>
  end

  def normalise_ip_address({a, b, c, d, e, f, g, h}) do
    <<h::16, g::16, f::16, e::16, d::16, c::16, b::16, a::16>>
  end

  def denormalise_ip_address(ip_address)

  def denormalise_ip_address(<<d::8, c::8, b::8, a::8, 0::96>>) do
    {a, b, c, d}
  end

  def denormalise_ip_address(<<h::16, g::16, f::16, e::16, d::16, c::16, b::16, a::16>>) do
    {a, b, c, d, e, f, g, h}
  end

  defp get_secret_key_base() do
    <<x::256, _::128>> = Base.decode64!(Application.get_env(:qtfile, :secret_key_ip))
    <<x::256>>
  end
end
