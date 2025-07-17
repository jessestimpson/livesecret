import Encryption from "../encryption";

const DecryptSecret = {
  mounted() {
    this.el.addEventListener("submit", async (event) => {
      if (!this.shouldSubmit()) {
        // prevent the event from bubbling to the default LiveView handler
        event.stopPropagation();

        // prevent the default browser behavior (submitting the form over HTTP)
        event.preventDefault();

        var form = this.el;

        var ciphertextEl = document.getElementById("ciphertext");
        var ivEl = document.getElementById("iv");
        var passphraseformEl = document.getElementById("passphraseform");
        var successmessageEl = document.getElementById("successmessage");
        var passphraseEl = document.getElementById("passphrase");
        var cleartextEl = document.getElementById("cleartext");
        var cleartextDivEl = document.getElementById("cleartext-container");
        var decryptionfailureDivEl = document.getElementById(
          "decryptionfailure-container",
        );
        var failCounterEl = document.getElementById("fail-counter");

        var userkey = passphraseEl.value;
        var ivVal = ivEl.value;
        var ciphertextVal = ciphertextEl.value;

        try {
          decryptedData = await Encryption.DecryptSecret(
            userkey,
            ivVal,
            ciphertextVal,
          );
        } catch (e) {
          var count = parseInt(failCounterEl.textContent) + 1;
          failCounterEl.textContent = count;
          if (count > 1) {
            failCounterEl.classList.remove("hidden");
          }
          decryptionfailureDivEl.classList.remove("hidden");
          return;
        }

        passphraseformEl.classList.add("hidden");
        successmessageEl.classList.remove("hidden");
        passphraseEl.value = "";
        ciphertextEl.value = "";
        ivEl.value = "";

        var burnkey = decryptedData.burnkey;
        var cleartext = decryptedData.cleartext;

        var burnkeyEl = document.getElementById("burnkey");
        burnkeyEl.value = burnkey;

        this.submit_flag = true;
        form.dispatchEvent(
          new Event("submit", { bubbles: true, cancelable: true }),
        );

        cleartextDivEl.classList.remove("hidden");
        decryptionfailureDivEl.classList.add("hidden");
        cleartextEl.value = cleartext;
        cleartextEl.style.height = "";
        cleartextEl.style.height = cleartextEl.scrollHeight + "px";

        var closeBtnEl = document.getElementById("close-btn");
        var decryptBtnEl = document.getElementById("decrypt-btn");
        decryptBtnEl.setAttribute(
          "phx-click",
          closeBtnEl.getAttribute("phx-click"),
        );
        decryptBtnEl.textContent = "OK";
        decryptBtnEl.type = "button";
      }
    });
  },
  shouldSubmit() {
    return this.submit_flag;
  },
};
export default DecryptSecret;
