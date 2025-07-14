import Encryption from "../encryption";

const CreateSecret = {
  mounted() {
    this.el.addEventListener("submit", async (event) => {
      if (!this.shouldSubmit()) {
        // prevent the event from bubbling to the default LiveView handler
        event.stopPropagation();

        // prevent the default browser behavior (submitting the form over HTTP)
        event.preventDefault();

        var form = this.el;

        var writableElements = [];
        var enabledElements = [];

        // Disable everything while we encrypt
        //console.log("Disabling form...");
        var elements = form.elements;
        for (var i = 0, len = elements.length; i < len; ++i) {
          var el = elements[i];
          if (el.readOnly == false) {
            el.readOnly = true;
            writableElements.push(el);
          }

          if (el.disabled == false) {
            el.disabled = true;
            enabledElements.push(el);
          }
        }

        // Prepare or generate passphrase for the user
        var passphrase = document.getElementById("passphrase");
        var userkey = null;
        if (passphrase.value == "") {
          //console.log("Generating passphrase...");
          const {
            host,
            hostname,
            href,
            origin,
            pathname,
            port,
            protocol,
            search,
          } = window.location;

          var url = origin + "/eff_large_wordlist.json";
          var data = await fetch(url);
          var wordlist = await data.json();

          userkey = await Encryption.GeneratePassphrase(wordlist);
        } else {
          //console.log("Found user provided passphrase");
          userkey = passphrase.value;
        }

        var burnkeyEl = document.getElementById("burnkey");
        var burnkey = burnkeyEl.value;

        var ivEl = document.getElementById("iv");
        var ivVal = ivEl.value;

        var cleartextEl = document.getElementById("cleartext");
        var cleartextVal = cleartextEl.value;
        cleartextEl.value = "";
        cleartextEl.placeholder = "...";

        passphrase.value = "";
        passphrase.placeholder = "...";

        var ciphertextVal = await Encryption.EncryptSecret(
          userkey,
          ivVal,
          burnkey,
          cleartextVal,
        );

        // Set hidden_input :content to the encrypted data
        var ciphertextEl = document.getElementById("ciphertext");
        ciphertextEl.value = ciphertextVal;

        //console.log("Submitting form...");

        // Enable everything that we disabled so that the phoenix submit works
        // Otherwise, there is no data in the submission.
        for (var i = 0, len = writableElements.length; i < len; ++i) {
          writableElements[i].readOnly = false;
        }

        for (var i = 0, len = enabledElements.length; i < len; ++i) {
          enabledElements[i].disabled = false;
        }

        this.submit_flag = true;
        form.dispatchEvent(
          new Event("submit", { bubbles: true, cancelable: true }),
        );

        // Stash the passphrase
        var userkeyStashEl = document.getElementById("userkey-stash");
        userkeyStashEl.value = userkey;
      }
    });
  },
  shouldSubmit() {
    return this.submit_flag;
  },
};
export default CreateSecret;
