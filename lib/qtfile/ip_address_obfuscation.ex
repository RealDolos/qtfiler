defmodule Qtfile.IPAddressObfuscation do
  require Logger

  def ip_filter(room, user, %{ip_address: ip_address} = data) do
    case user.role do
      "admin" -> %{data | ip_address: human_readable(
                    denormalise_ip_address(Base.decode64!(data.ip_address)))}
      "mod" -> %{data | ip_address: encrypt_ip_address(data.ip_address, user.secret)}
      "user" -> Map.delete(data, :ip_address)
    end
  end

  def ban_filter(room, user, ip_address) do
    case user.role do
      "admin" -> {:ok, ip_address}
      "mod" -> decrypt_ip_address(ip_address, user.secret)
      "user" -> :error
    end
  end

  def human_readable(ip_address)

  def human_readable({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  def human_readable({a, b, c, d, e, f, g, h}) do
    [a, b, c, d, e, f, g, h] = Enum.map([a, b, c, d, e, f, g, h], fn(chunk) ->
      Base.encode16(chunk)
    end)
    "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
  end

  defp encrypt_ip_address(ip_address, iv) do
    Logger.info ip_address
    Logger.info iv
    pt = Base.decode64(ip_address)
    Logger.info pt
    key = get_secret_key_base()
    Logger.info key
    {ct, mac} = :crypto.block_encrypt(:chacha20_poly1305, key, iv, {iv, pt})
    Logger.info ct
    Logger.info mac
    result = <<ct::128, mac::128>>
    Base.url_encode64(result)
  end

  defp decrypt_ip_address(encrypted_ip_address, iv) do
    key = get_secret_key_base()
    <<ct::128, mac::128>> = Base.url_decode64!(encrypted_ip_address)
    case :crypto.block_decrypt(:chacha20_poly1305, key, iv, {iv, ct, mac}) do
      :error -> :error
      pt -> {:ok, Base.encode64(pt)}
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

  defp generate_encryption_key(room, user, token) do
    :crypto.hmac(:sha256, get_secret_key_base(), <<room.id::64, user.id::64, token::128>>)
  end

  defp get_secret_key_base() do
    <<x::256, _>> = Base.decode64!(Application.get_env(:qtfile, :token_secret_key_base))
    x
  end
end
