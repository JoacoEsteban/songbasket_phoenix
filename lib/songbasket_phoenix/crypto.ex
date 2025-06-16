defmodule SongbasketPhoenix.Crypto do
  @algorithm :aes_256_gcm
  @key_length 32
  @iv_length 12

  def encrypt(plaintext) do
    key =
      fetch_key!()

    32 = byte_size(key)

    iv = :crypto.strong_rand_bytes(@iv_length)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(@algorithm, key, iv, plaintext, "", true)

    iv <> tag <> ciphertext
  end

  def decrypt(payload) do
    key = fetch_key!()
    <<iv::binary-size(@iv_length), tag::binary-size(16), ciphertext::binary>> = payload
    :crypto.crypto_one_time_aead(@algorithm, key, iv, ciphertext, "", tag, false)
  end

  defp fetch_key! do
    Application.fetch_env!(:songbasket_phoenix, :encryption_key)
  end
end
