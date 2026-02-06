
function importKey(rawkey) {
  return window.crypto.subtle.importKey(
    "raw",
    rawkey,
    {
      name: "AES-GCM",
    },
    false, // non-extractable
    ["encrypt", "decrypt"]
  );
}

function exportKey(key) {
  return window.crypto.subtle.exportKey("raw", key);
}

function generateKey() {
  return window.crypto.subtle.generateKey(
    {
      name: "AES-GCM",
      length: 256,
    },
    true, // extractable
    ["encrypt", "decrypt"]
  );
}

function encrypt(data, key, iv) {
  return window.crypto.subtle.encrypt(alg(iv), key, data);
}

function decrypt(data, key, iv) {
  return window.crypto.subtle.decrypt(alg(iv), key, data);
}

function alg(iv) {
  return {
    name: "AES-GCM",
    iv: iv,
    tagLength: 128,
  };
}

function sha256(buffer) {
  return window.crypto.subtle.digest("SHA-256", buffer);
}

function arrayBufferToBase64(buffer) {
  var bytes = new Uint8Array(buffer);
  return bytesToBase64(bytes);
}

function bytesToBase64(bytes) {
  var binary = '';
  var len = bytes.byteLength;
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window.btoa(binary);
}

function base64ToArrayBuffer(base64) {
  var binary_string = window.atob(base64);
  var len = binary_string.length;
  var bytes = new Uint8Array(len);
  for (var i = 0; i < len; i++) {
    bytes[i] = binary_string.charCodeAt(i);
  }
  return bytes.buffer;
}

const GeneratePassphrase = async function (wordlist) {
  var encryptionkey = await generateKey();
  var rawkey = await exportKey(encryptionkey);

  if (wordlist.length != 7776) { // eff_large_wordlist.txt|json
    var userkey = arrayBufferToBase64(rawkey);
    return userkey;
  } else {
    // Assume the wordlist provided is from eff_large_wordlist
    //    * Entries are based on 5 indepdent d6 roles
    //    * The generated 256bit encryptionkey is equivalent to
    //      99 dice rolls
    //    * We can generate up to 19 words, but 4 is enough
    const effBase = 6;
    const effChunk = 5;
    const numWords = 4;

    var rawbytes = new Uint8Array(rawkey.slice());

    var rolls = convertBase(rawbytes, effBase);
    if (numWords * effChunk > rolls.length) {
      userkey = arrayBufferToBase64(rawkey);
      return userkey;
    }

    var passphraseWords = [];
    for (let i = 0; i < rolls.length; i += effChunk) {
      const wordIndexArray = rolls.slice(i, i + effChunk);
      var wordIndex = 0;
      for (let j = 0; j < wordIndexArray.length; ++j) {
        wordIndex += wordIndexArray[j] * Math.pow(effBase, j);
      }
      passphraseWords.push(capitalizeFirstLetter(wordlist[wordIndex]));
      if (passphraseWords.length >= numWords) {
        break;
      }
    }
    return passphraseWords.join('');
  }
}

function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

function convertBase(byteArray, outputBase) {
  //takes a bigint string and converts to different base
  var outputValues = [], //output array, little-endian/lsd order
    remainder,
    len = byteArray.length,
    pos = 0,
    i,
    inputBase = 256;
  while (pos < len) { //while digits left in input array
    remainder = 0; //set remainder to 0
    for (i = pos; i < len; i++) {
      //long integer division of input values divided by output base
      //remainder is added to output array
      remainder = byteArray[i] + remainder * inputBase;
      byteArray[i] = Math.floor(remainder / outputBase);
      remainder -= byteArray[i] * outputBase;
      if (byteArray[i] == 0 && i == pos) {
        pos++;
      }
    }
    outputValues.push(remainder);
  }
  outputValues.reverse(); //transform to big-endian/msd order
  return outputValues;
}

const EncryptSecret = async function (userkey, ivVal, burnkey, cleartextVal) {

  var encoder = new TextEncoder();

  var iv = base64ToArrayBuffer(ivVal);

  var userkeyBuffer = await sha256(encoder.encode(userkey));
  var encryptionkey = await importKey(userkeyBuffer);


  // Read and clear the input in the form
  var data = encoder.encode(burnkey + "\n" + cleartextVal);

  var ciphertextBuffer = await encrypt(data, encryptionkey, iv);
  var ciphertextVal = arrayBufferToBase64(ciphertextBuffer);
  return ciphertextVal;
}

const DecryptSecret = async function (userkey, ivVal, ciphertextVal) {
  var encoder = new TextEncoder();

  var iv = base64ToArrayBuffer(ivVal);

  var userkeyBuffer = await sha256(encoder.encode(userkey));
  var encryptionkey = await importKey(userkeyBuffer);
  var decryptedData = await decrypt(base64ToArrayBuffer(ciphertextVal), encryptionkey, iv);
  var decoder = new TextDecoder("utf-8");
  var res = decoder.decode(decryptedData)

  // The first line is the key that allows us to burn the message
  var burnkey = res.split('\n')[0].trim();
  var cleartext = res.substring(res.indexOf("\n") + 1);

  return { burnkey: burnkey, cleartext: cleartext }
}

let Encryption = {
  GeneratePassphrase: GeneratePassphrase,
  EncryptSecret: EncryptSecret,
  DecryptSecret: DecryptSecret
}

export default Encryption;
