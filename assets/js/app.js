// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Hooks from "./hooks";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

window.addEventListener("error", (event) => {
  console.log("Error detected. Making sure the userkey is removed");
  var userkeyStashEl = document.getElementById("userkey-stash");
  if (userkeyStashEl) {
    userkeyStashEl.value = "";
  }
});

window.addEventListener("live-secret:clipcopy", (event) => {
  if ("clipboard" in navigator) {
    const text = event.target.value;
    if (text == "") {
    } else {
      navigator.clipboard.writeText(text);
      event.target.classList.add("flash");
      setTimeout(() => {
        event.target.classList.remove("flash");
      }, 200);
    }
  } else {
    alert("Sorry, your browser does not support clipboard copy.");
  }
});

window.addEventListener("live-secret:clipcopy-instructions", (event) => {
  //console.log("Generating instructions...");
  var userkeyStashEl = document.getElementById("userkey-stash");

  var flashUserkey = true;

  var passphrase = userkeyStashEl.value;
  if (userkeyStashEl.value === "") {
    passphrase = "<Admin must provide the passphrase>";
    flashUserkey = false;
  }

  var oobUrlEl = document.getElementById("oob-url");

  var initiator = document.getElementById("secret-initiator-input").value;

  var instructions =
    `Hi, I'd like to share an encrypted message with you via LiveSecret.
1. Open this link in your browser:
\`\`\`
` +
    oobUrlEl.value +
    `
\`\`\`
2. When prompted, enter the following passphrase:
\`\`\`
` +
    passphrase +
    `
\`\`\``;

  if (initiator == "recipient") {
    instructions = "something else";
  }

  if ("clipboard" in navigator) {
    navigator.clipboard.writeText(instructions);
    oobUrlEl.classList.add("flash");
    if (flashUserkey) {
      userkeyStashEl.classList.add("flash");
    }

    setTimeout(() => {
      oobUrlEl.classList.remove("flash");
      userkeyStashEl.classList.remove("flash");
    }, 200);
  } else {
    alert("Sorry, your browser does not support clipboard copy.");
  }
});

window.addEventListener("live-secret:select-choice", (event) => {
  event.target.value = event.detail.value;
  event.target.dispatchEvent(new Event("input", { bubbles: true }));
});
