# LiveSecret

[**LiveSecret**](https://livesecret.link) is a [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
web application built for secure sharing of passwords or other secrets.
The secret content is End-to-End Encrypted using your browser's built-in cryptography
library, [SubtleCrypto](https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto).

The following video demonstrates authoring a secret, unlocking it for a recipient, and
the recipient decrypting it in another window.

https://github.com/user-attachments/assets/1dcd4e68-12bf-4aed-bcc0-bfad6ba53630

## Disclaimer

Because encryption is done within the browser, LiveSecret relies on the
physical security of the user's personal computer or mobile device. You should only
use LiveSecret from a *trusted endpoint*, and only if it's *hosted by someone
you trust*.

Also, LiveSecret has not undergone a security audit, so it doesn't provide any guarantees,
especially those regarding any technical claims made by the author.

As a user of LiveSecret you alone are responsible for securing secret content.

## Features
* [End-to-End Encryption with out-of-band key](#e2ee-with-oob-key)
* [Live Presence](#live-presence) and [Live Secrets](#live-secrets)
* [Burn after reading](#burn-after-reading)
* [Link expiration](#link-expiration)
* [Admin view](#admin-view)

### E2EE with OOB key
When you author a secret with LiveSecret, it is encrypted within your browser. The ciphertext
is written to the server, but the cleartext is only held locally, and it's removed from your
browser's memory at some point after the encryption event; the exact timing is dependent
on the browser.

LiveSecret always uses a passphrase-like encryption key to encrypt the secret content. When you
author a secret, if you don't specify a passphrase, one will be generated for you. The passphrase
is stored locally in the browser and is never transmitted to the server in any form.

As the author of a secret, you will be required to transmit the passphrase [out-of-band](https://en.wikipedia.org/wiki/Out-of-band_data) with the
intended recipient. You're responsible for the method used for this transmission.

### Live Presence
Each secret created with LiveSecret has a unique [non-enumerable URL](https://en.wikipedia.org/wiki/Network_enumeration).
When a someone renders this
URL in a browser, a Phoenix LiveView is loaded and the visitor's presence is tracked. All visitors
to this page can view the presence of all other users, and metadata is displayed for each including:

* Admin | Recipient
* Peer address and port
* Timestamp of joining | timestamp of leaving
* Locked | Unlocked | Revealed status

The LiveView is updated for all users as the secret is Decrypted and Burned. You never need to refresh
the page.

### Live Secrets
**Live mode is for synchronous sharing.** When a secret is in Live mode, all users are Locked by default, which means
the LiveSecret server will prevent the ciphertext from being sent to the client. This locks them out from decrypting
the secret even if they know the passphrase. An Admin can unlock a recipient by clicking the `Locked`
button in the Admin View. When a recipient is Unlocked, they will be prompted for the passphrase, and if correct,
the cleartext content is displayed.

**Async mode is for asynchronous sharing.** When a secret is in Async mode, all users are Unlocked by default.
If an attacker intercepts the URL and passphrase before the secret is burned, they will be able to decrypt the message.

### Burn after reading
After a successful decryption event, the ciphertext is deleted from the server. This makes it very
likely that the cleartext is revealed to exactly 2 people: the author and the
receiver. While we can't give a cryptographic guarantee that exactly 2 clients were involved,
Live Presence can help to bolster the likelihood. Also, Live-mode Secrets give near-certainty that
the cleartext is revealed only to the expected recipient.

Once burned, the URL can still be visited, but there are no actions to be taken by any party. A
burned secret is essentially a tombstone.

### Link expiration
When you author a secret, you choose the expiration period for all the information stored on the
server (ciphertext, iv, and metadata). After the expiration period, all this information will be
deleted from the database. If a user visits the URL for this secret after the expiration,
they will be informed that the secret does not exist.

### Admin view
The author of the secret can perform a limited set of actions on the secret after creation. This
includes:

1. Unlocking users in Live Presence
2. Burning the secret
3. Turning Live mode on or off

**The Admin View cannot view or decrypt the ciphertext.**

## Getting Started

To start the LiveSecret Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Tailwind CSS with `mix tailwind.install`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * Run the tests with `mix test`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Ready to run in production?

Please [check Phoenix's deployment guides](https://hexdocs.pm/phoenix/deployment.html).

#### Docker Compose

We provide a compose.yaml: it uses nginx-proxy to set up a reverse proxy and acme-companion
to manage the SSL certificate. We host a publicly accessible LiveSecret at livesecret.link, and
the instructions here reflect that deployment.

You're encouraged to host your own server. If it's not publicly accessible, you'll have to
change the configuration to suit your needs.

```bash
touch .env
# For livesecret.link, the .env file contains:
#
#   export PHX_HOST=livesecret.link
#   export SECRET_KEY_BASE=<result of mix phx.gen.secret>
#   export DEFAULT_EMAIL=<my email address>
#
source .env
docker compose build
docker compose up # Optional: -d for detached mode
```

#### Subtle Crypto requirements

**HTTPS**: `window.crypto.subtle` will return `undefined` on HTTP in an environment other than a local
environment (i.e. localhost). Hence, to run LiveSecret on an actual domain
name on the internet, you need to set up SSL (HTTPS). See [Mozilla | Secure Contexts](developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts)
for more information.

#### Deployment Configuration

Standard Phoenix:
* `DATABASE_PATH`: Filesystem directory in which store LiveSecret database files
* `PHX_HOST`: The hostname that is presented to the user's browser
* `PORT`: The port that Phoenix listens on
* `SECRET_KEY_BASE`: Standard Phoenix env var for encrypting cookie, etc

Unique to LiveSecret:
* `LIVESECRET_DATABASE`: When `"embed"` LiveSecret uses an embedded database. Otherwise, the operator must provide a remote database.
* `BEHIND_PROXY`: When `"true"` LiveSecret Presence discovers the user's IP address via the
   configured x-header. It is strongly recommended to use a reverse proxy.
* `REMOTE_IP_HEADER`: The trusted x-header that presents the end user's IP address. It must
   start with "x-"

FoundationDB paths:
* `FDBMONITOR_PATH`
* `FDBCLI_PATH`
* `FDBSERVER_PATH`

## Learn more about Phoenix

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
