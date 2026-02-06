// Bun provides crypto, btoa, atob as globals but encryption.js
// references them via window.* — shim that here.
import { beforeAll } from "bun:test";

beforeAll(() => {
  globalThis.window = globalThis.window || {};
  window.crypto = globalThis.crypto;
  window.btoa = globalThis.btoa;
  window.atob = globalThis.atob;
});
