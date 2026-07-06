package uz.agroinvest.common.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.AEADBadTagException;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * AES-GCM (authenticated encryption) for PII at rest - passport numbers, KYC documents.
 * Each call generates a fresh random 12-byte IV, so encrypting the same plaintext twice
 * yields different ciphertext (unlike the previous AES/ECB implementation, which leaked
 * patterns and had no integrity check at all).
 */
@Component
public class EncryptionUtil {

    private static final Logger logger = LoggerFactory.getLogger(EncryptionUtil.class);
    private static final String TRANSFORMATION = "AES/GCM/NoPadding";
    private static final int GCM_IV_LENGTH_BYTES = 12;
    private static final int GCM_TAG_LENGTH_BITS = 128;

    private final SecretKeySpec secretKey;
    private final SecureRandom secureRandom = new SecureRandom();

    public EncryptionUtil(@Value("${encryption.key}") String secretKeyRaw) {
        byte[] keyBytes = secretKeyRaw.getBytes(StandardCharsets.UTF_8);
        if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
            // Fail fast at startup rather than silently truncating/padding to a weaker
            // key length - a passport-data encryption key must be exactly what was configured.
            throw new IllegalStateException(
                    "encryption.key must be exactly 16, 24, or 32 bytes (AES-128/192/256); got "
                            + keyBytes.length + " bytes");
        }
        this.secretKey = new SecretKeySpec(keyBytes, "AES");
    }

    public String encrypt(String data) {
        if (data == null) return null;
        try {
            byte[] iv = new byte[GCM_IV_LENGTH_BYTES];
            secureRandom.nextBytes(iv);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] encrypted = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));

            ByteBuffer buffer = ByteBuffer.allocate(iv.length + encrypted.length);
            buffer.put(iv).put(encrypted);
            return Base64.getEncoder().encodeToString(buffer.array());
        } catch (Exception e) {
            logger.error("Encryption failed", e);
            throw new RuntimeException("Xavfsiz ma'lumotlarni shifrlashda xatolik yuz berdi");
        }
    }

    public String decrypt(String encryptedData) {
        if (encryptedData == null) return null;
        try {
            byte[] combined = Base64.getDecoder().decode(encryptedData);
            ByteBuffer buffer = ByteBuffer.wrap(combined);
            byte[] iv = new byte[GCM_IV_LENGTH_BYTES];
            buffer.get(iv);
            byte[] encrypted = new byte[buffer.remaining()];
            buffer.get(encrypted);

            Cipher cipher = Cipher.getInstance(TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] decrypted = cipher.doFinal(encrypted);
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (AEADBadTagException tampered) {
            logger.error("Decryption failed: ciphertext failed authentication (tampered or wrong key)");
            throw new RuntimeException("Xavfsiz ma'lumotlarni shifrini ochishda xatolik yuz berdi");
        } catch (Exception e) {
            logger.error("Decryption failed", e);
            throw new RuntimeException("Xavfsiz ma'lumotlarni shifrini ochishda xatolik yuz berdi");
        }
    }
}
