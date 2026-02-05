import Encryption from "../encryption";

function getByteLength(str) {
  return new TextEncoder().encode(str).length;
}

const CreateSecret = {
  mounted() {
    // Max cleartext size is configured server-side in this data attribute
    this.maxCleartextBytes = parseInt(this.el.dataset.maxCleartextSize, 10);

    this.setupContentValidation();

    this.el.addEventListener("submit", async (event) => {
      if (!this.shouldSubmit()) {
        // prevent the event from bubbling to the default LiveView handler
        event.stopPropagation();

        // prevent the default browser behavior (submitting the form over HTTP)
        event.preventDefault();

        if (!this.isContentValid()) {
          return;
        }

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

  setupContentValidation() {
    var cleartextEl = document.getElementById("cleartext");
    var warningEl = document.getElementById("content-length-warning");
    var messageEl = document.getElementById("content-length-message");
    var buttonEl = document.getElementById("encrypt-button");

    if (!cleartextEl || !warningEl || !buttonEl) {
      return;
    }

    var self = this;

    var maxBytes = self.maxCleartextBytes;

    var validateContent = function () {
      var byteLength = getByteLength(cleartextEl.value);
      var isOverLimit = byteLength > maxBytes;

      if (isOverLimit) {
        var overBy = byteLength - maxBytes;
        messageEl.textContent =
          "Your secret is " +
          overBy +
          " bytes over the maximum size of " +
          maxBytes +
          " bytes. Please shorten your content.";
        warningEl.classList.remove("hidden");
        buttonEl.disabled = true;
        self.contentTooLong = true;
      } else {
        warningEl.classList.add("hidden");
        buttonEl.disabled = false;
        self.contentTooLong = false;
      }
    };

    // Validate on input
    cleartextEl.addEventListener("input", validateContent);

    // Run initial validation in case there's pre-filled content
    validateContent();
  },

  isContentValid() {
    return !this.contentTooLong;
  },
};
export default CreateSecret;
