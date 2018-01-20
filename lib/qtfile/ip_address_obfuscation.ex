defmodule Qtfile.IPAddressObfuscation do

  def encrypt_ip_address(ip_address, room, user, token) do
    key = generate_encryption_key(room, user, token)
    :crypto.block_encrypt(:aes_cbc, key, normalise_ip_address(ip_address))
  end

  def decrypt_ip_address(encrypted_ip_address, room, user, token) do
    key = generate_encryption_key(room, user, token)
    denormalise_ip_address(:crypto.block_decrypt(:aes_cbc, key, encrypted_ip_address))
  end

  defp normalise_ip_address({a, b, c, d}) do
    <<0::96, a::8, b::8, c::8, d::8>>
  end

  defp normalise_ip_address({a, b, c, d, e, f, g, h}) do
    <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>
  end

  defp denormalise_ip_address(<<0::96, a::8, b::8, c::8, d::8>>) do
    {a, b, c, d}
  end

  defp denormalise_ip_address(<<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>) do
    {a, b, c, d, e, f, g, h}
  end

  defp generate_encryption_key(room, user, token) do
    :crypto.hmac(:sha256, get_secret_key_base(), <<room.id::64, user.id::64, token::128>>)
  end

  def generate_token() do
    :crypto.strong_rand_bytes(16)
  end

  defp get_secret_key_base() do
    Application.get_env(:qtfile, :token_secret_key_base) 
  end

  defp get_salt() do
    "ip_address_obfuscation_salt"
  end

  defp max_age() do
    86400
  end
end
