import Encryption from "./encryption";

async function CreateSecret(event) {
  var form = document.getElementById("secret-form");

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
    const { host, hostname, href, origin, pathname, port, protocol, search } =
      window.location;

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

  form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));

  // Stash the passphrase
  var userkeyStashEl = document.getElementById("userkey-stash");
  userkeyStashEl.value = userkey;
}

async function DecryptSecret() {
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
  burnkeyEl.dispatchEvent(new Event("input", { bubbles: true }));

  cleartextDivEl.classList.remove("hidden");
  decryptionfailureDivEl.classList.add("hidden");
  cleartextEl.value = cleartext;
  cleartextEl.style.height = "";
  cleartextEl.style.height = cleartextEl.scrollHeight + "px";

  var closeBtnEl = document.getElementById("close-btn");
  var decryptBtnEl = document.getElementById("decrypt-btn");
  decryptBtnEl.setAttribute("phx-click", closeBtnEl.getAttribute("phx-click"));
  decryptBtnEl.textContent = "OK";
}

let Events = {
  CreateSecret: CreateSecret,
  DecryptSecret: DecryptSecret,
};

export default Events;
