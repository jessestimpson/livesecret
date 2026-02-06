import { describe, test, expect } from "bun:test";
import Encryption from "../../assets/js/encryption.js";

describe("EncryptSecret and DecryptSecret", () => {
  test("roundtrip encrypt then decrypt returns original content", async () => {
    const passphrase = "test-passphrase-123";
    const iv = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const burnkey = "my-burn-key";
    const cleartext = "Hello, this is a secret message!";

    const ciphertext = await Encryption.EncryptSecret(passphrase, iv, burnkey, cleartext);
    expect(ciphertext).toBeTruthy();
    expect(typeof ciphertext).toBe("string");

    const result = await Encryption.DecryptSecret(passphrase, iv, ciphertext);
    expect(result.burnkey).toBe(burnkey);
    expect(result.cleartext).toBe(cleartext);
  });

  test("decrypt with wrong passphrase fails", async () => {
    const passphrase = "correct-passphrase";
    const iv = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const burnkey = "burn";
    const cleartext = "secret";

    const ciphertext = await Encryption.EncryptSecret(passphrase, iv, burnkey, cleartext);

    expect(
      Encryption.DecryptSecret("wrong-passphrase", iv, ciphertext)
    ).rejects.toThrow();
  });

  test("different IVs produce different ciphertexts", async () => {
    const passphrase = "same-passphrase";
    const iv1 = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const iv2 = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const burnkey = "burn";
    const cleartext = "same content";

    const ct1 = await Encryption.EncryptSecret(passphrase, iv1, burnkey, cleartext);
    const ct2 = await Encryption.EncryptSecret(passphrase, iv2, burnkey, cleartext);

    expect(ct1).not.toBe(ct2);
  });

  test("handles empty cleartext", async () => {
    const passphrase = "passphrase";
    const iv = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const burnkey = "burn";
    const cleartext = "";

    const ciphertext = await Encryption.EncryptSecret(passphrase, iv, burnkey, cleartext);
    const result = await Encryption.DecryptSecret(passphrase, iv, ciphertext);
    expect(result.burnkey).toBe(burnkey);
    expect(result.cleartext).toBe(cleartext);
  });

  test("handles unicode content", async () => {
    const passphrase = "passphrase";
    const iv = btoa(String.fromCharCode(...crypto.getRandomValues(new Uint8Array(12))));
    const burnkey = "burn";
    const cleartext = "Hello \u{1F30D} \u00E9\u00E0\u00FC \u4F60\u597D";

    const ciphertext = await Encryption.EncryptSecret(passphrase, iv, burnkey, cleartext);
    const result = await Encryption.DecryptSecret(passphrase, iv, ciphertext);
    expect(result.burnkey).toBe(burnkey);
    expect(result.cleartext).toBe(cleartext);
  });
});

describe("GeneratePassphrase", () => {
  test("returns base64 string when wordlist is not 7776 entries", async () => {
    const passphrase = await Encryption.GeneratePassphrase([]);
    expect(passphrase).toBeTruthy();
    expect(typeof passphrase).toBe("string");
    // Should be valid base64 (44 chars for a 256-bit key)
    expect(passphrase.length).toBe(44);
  });

  test("returns word-based passphrase with 7776-entry wordlist", async () => {
    // Create a fake 7776-entry wordlist
    const wordlist = Array.from({ length: 7776 }, (_, i) => `word${i}`);
    const passphrase = await Encryption.GeneratePassphrase(wordlist);
    expect(passphrase).toBeTruthy();
    expect(typeof passphrase).toBe("string");
    // Should be capitalized words joined together (no spaces)
    expect(passphrase).not.toContain(" ");
    // First character should be uppercase
    expect(passphrase[0]).toBe(passphrase[0].toUpperCase());
  });

  test("generates different passphrases each time", async () => {
    const p1 = await Encryption.GeneratePassphrase([]);
    const p2 = await Encryption.GeneratePassphrase([]);
    // Cryptographically random, so extremely unlikely to collide
    expect(p1).not.toBe(p2);
  });

  test("returns 4-word passphrase from real EFF wordlist", async () => {
    const wordlist = await Bun.file("priv/static/eff_large_wordlist.json").json();
    expect(wordlist.length).toBe(7776);

    const passphrase = await Encryption.GeneratePassphrase(wordlist);
    expect(passphrase).toBeTruthy();

    // Each word is capitalized, so count uppercase letters to find word boundaries
    const uppercaseCount = (passphrase.match(/[A-Z]/g) || []).length;
    expect(uppercaseCount).toBe(4);

    // Every word in the passphrase should come from the wordlist
    // Split on uppercase boundaries to extract individual words
    const words = passphrase.split(/(?=[A-Z])/).map((w) => w.toLowerCase());
    for (const word of words) {
      expect(wordlist).toContain(word);
    }
  });
});
