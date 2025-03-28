defmodule LiveSecretWeb.PageComponents do
  use Phoenix.Component
  use PhoenixHTMLHelpers
  alias Phoenix.LiveView.JS

  attr :user, :any
  attr :burned_at, :any

  def receiver_instructions(assigns) do
    ~H"""
    <%= case {not is_nil(@burned_at), @user.state} do %>
      <% {false, :locked} -> %>
        <.instructions type={:wait_for_unlock} />
      <% {false, :unlocked} -> %>
        <.instructions type={:do_decrypt} />
      <% {true, _} -> %>
        <.instructions type={:done} />
      <% _ -> %>
    <% end %>
    """
  end

  attr :burned_at, :any
  attr :live?, :boolean

  def admin_instructions(assigns) do
    ~H"""
    <%= case {not is_nil(@burned_at), @live?} do %>
      <% {false, true} -> %>
        <.instructions type={:do_unlock} />
      <% {false, false} -> %>
        <.instructions type={:do_nothing} />
      <% {true, _} -> %>
        <.instructions type={:done} />
      <% _ -> %>
    <% end %>
    """
  end

  attr :type, :atom, required: true

  def instructions(assigns) do
    # <%= case {not is_nil(@burned_at), @user.state} do %>
    #  <% {false, :locked} -> %>
    # <% {true, _} -> %>
    ~H"""
    <div class="pt-8 px-8 pb-2 w-full flex justify-center items-center align-center text-gray-700">
      <.instructions_card :if={@type == :wait_for_unlock} color={:yellow}>
        <:icon>
          <div role="status" class="pl-2">
            <svg
              aria-hidden="true"
              class="mr-2 w-4 h-4 text-gray-200 animate-spin dark:text-gray-600 fill-gray-800"
              viewBox="0 0 100 101"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                fill="currentColor"
              />
              <path
                d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                fill="currentFill"
              />
            </svg>
            <span class="sr-only">Loading...</span>
          </div>
        </:icon>
        <:title>Please wait</:title>
        <:description>The <strong>Admin</strong> must unlock your page</:description>
      </.instructions_card>
      <.instructions_card :if={@type == :do_decrypt} color={:yellow} id="decrypt-instructions" class="hidden">
        <:icon>👉</:icon>
        <:title>Ready</:title>
        <:description>
          <button
            type="button"
            id="show-btn"
            class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-1 sm:mt-0 sm:text-sm"
            phx-click={JS.show(to: "#decrypt-modal") |> JS.hide(to: "#decrypt-instructions")}
          >
            Receive secret
          </button>
        </:description>
      </.instructions_card>
      <.instructions_card :if={@type == :done} color={:blue}>
        <:icon>👋</:icon>
        <:title>Goodbye</:title>
        <:description>We're all done here. Please close this window.</:description>
      </.instructions_card>
      <.instructions_card :if={@type == :do_unlock} color={:yellow}>
        <:icon>🤝</:icon>
        <:title>Live Mode</:title>
        <:description>
          When the intended <strong>Recipient</strong> comes online, press
          <LiveSecretWeb.UserListComponent.badge enabled={false} icon={:lock} text="Locked" class="" />
        </:description>
      </.instructions_card>
      <.instructions_card :if={@type == :do_nothing} color={:yellow}>
        <:icon>🙌</:icon>
        <:title>Async Mode</:title>
        <:description>
          When any <strong>Recipient</strong> comes online, they will be prompted for the passphrase
        </:description>
      </.instructions_card>
    </div>
    """
  end

  attr :id, :string, default: ""
  attr :class, :string, default: ""
  attr :color, :atom
  slot :icon
  slot :title
  slot :status
  slot :description

  def instructions_card(assigns) do
    ~H"""
    <div id={@id} class={[
      "rounded-md p-4",
      @class,
      case @color do
        :blue -> "bg-blue-50"
        :yellow -> "bg-yellow-50"
      end
    ]}>
      <div class="flex">
        <div class="flex-shrink-0">{render_slot(@icon)}</div>
        <div class="ml-3">
          <div class="flex">
            <h3 class={[
              "text-base font-medium",
              case @color do
                :blue -> "text-blue-800"
                :yellow -> "text-yellow-800"
              end
            ]}>
              {render_slot(@title)}
            </h3>
          </div>
          <div class={[
            "mt-2 text-sm",
            case @color do
              :blue -> "text-blue-700"
              :yellow -> "text-yellow-700"
            end
          ]}>
            <p>{render_slot(@description)}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Rendered for live_action = :create | :admin so that the passphrase can be held in the DOM
  def secret_links(assigns) do
    ~H"""
    <% container_class = if @live_action == :create, do: "", else: "pt-8 px-8 pb-2" %>
    <div class={container_class}>
      <ul>
        <%= if @live_action == :admin do %>
          <% url = Application.fetch_env!(:livesecret, LiveSecretWeb.Endpoint)[:url] %>
          <% scheme = url[:scheme] || "http" %>
          <% host = url[:host] || "localhost" %>
          <% port = url[:port] || 4000 %>
          <% oob_url = build_external_url(scheme, host, port, @to) %>

          <div class="w-full flex justify-center items-center align-center">
            <button
              type="button"
              class={"text-blue-700 bg-blue-100 hover:bg-blue-200 focus:ring-blue-500 inline-flex items-center justify-center rounded-md border border-transparent px-4 py-2 font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 sm:text-sm "<> if @enabled, do: "", else: "line-through"}
              phx-click={JS.dispatch("live-secret:clipcopy-instructions")}
              disabled={not @enabled}
            >
              Copy as Markdown <.action_icon has_text={true} id={:markdown} />
            </button>
            <div :if={@enabled} id="show-passphrase-after-create" phx-hook="ShowPassphraseAfterCreate">
            </div>
          </div>
          <.copiable
            id="oob-url"
            type={:text}
            value={oob_url}
            ignore={false}
            enabled={@enabled}
            placeholder=""
          />
        <% end %>

        <% input_type = if @live_action == :create, do: :hidden, else: :text %>
        <.copiable
          id="userkey-stash"
          type={input_type}
          value=""
          ignore={true}
          enabled={@enabled}
          placeholder="<Admin must provide the passphrase>"
        />
      </ul>
    </div>
    """
  end

  def action_panel(assigns) do
    ~H"""
    <div class="py-4">
      <ul
        role="list"
        class="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-2 2xl:grid-cols-2"
      >
        <.action_item
          title="Burn this secret"
          description="When you burn the secret, the encrypted data is deleted forever."
          action_enabled={is_nil(@burned_at)}
          action_text="Burn"
          action_icon={:fire}
          action_class="text-red-700 bg-red-100 hover:bg-red-200 focus:ring-red-500"
          action_click="burn"
        >
        </.action_item>

        <%= if @live? do %>
          <.action_item
            title="Switch to Async Mode"
            description="Async mode will auto-unlock anyone who visits the secret link. The secret content is still burned after the first decryption event. However, multiple clients could connect at the same time."
            action_enabled={is_nil(@burned_at)}
            action_text="Go Async"
            action_icon={:unlocked}
            action_class="text-blue-700 bg-blue-100 hover:bg-blue-200 focus:ring-blue-500"
            action_click="go_async"
          />
        <% else %>
          <.action_item
            title="Switch to Live Mode"
            description="In Live mode, the Admin must remain on this page to unlock the intended recipient when they connect."
            action_enabled={is_nil(@burned_at)}
            action_text="Go Live"
            action_icon={:locked}
            action_class="text-blue-700 bg-blue-100 hover:bg-blue-200 focus:ring-blue-500"
            action_click="go_live"
          />
        <% end %>
      </ul>
    </div>
    """
  end

  def action_item(assigns) do
    ~H"""
    <li class="col-span-1 rounded-lg bg-white shadow">
      <div class="flex w-full items-center justify-between space-x-6 p-6">
        <div class="flex-1">
          <div class="flex items-center space-x-3">
            <h3 class="truncate text-sm font-medium text-gray-900">{@title}</h3>
          </div>
          <p class="mt-1 text-sm text-gray-500">{@description}</p>
        </div>
      </div>
      <div class="inline-flex w-full items-center justify-center pb-4">
        <button
          type="button"
          class={"#{@action_class} inline-flex items-center justify-center rounded-md border border-transparent px-4 py-2 font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 sm:text-sm "<> if @action_enabled, do: "", else: "line-through"}
          phx-click={if @action_enabled, do: @action_click}
          disabled={not @action_enabled}
        >
          {@action_text}
          <.action_icon :if={not is_nil(@action_icon)} has_text={true} id={@action_icon} />
        </button>
      </div>
    </li>
    """
  end

  defp action_icon(assigns) do
    ~H"""
    <% margin_for_left_text = if @has_text, do: "ml-2", else: "-ml-1" %>
    <%= case @id do %>
      <% :fire -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          class={margin_for_left_text<>" -mr-1 w-5 h-5"}
        >
          <path
            fill-rule="evenodd"
            d="M13.5 4.938a7 7 0 11-9.006 1.737c.202-.257.59-.218.793.039.278.352.594.672.943.954.332.269.786-.049.773-.476a5.977 5.977 0 01.572-2.759 6.026 6.026 0 012.486-2.665c.247-.14.55-.016.677.238A6.967 6.967 0 0013.5 4.938zM14 12a4 4 0 01-4 4c-1.913 0-3.52-1.398-3.91-3.182-.093-.429.44-.643.814-.413a4.043 4.043 0 001.601.564c.303.038.531-.24.51-.544a5.975 5.975 0 011.315-4.192.447.447 0 01.431-.16A4.001 4.001 0 0114 12z"
            clip-rule="evenodd"
          />
        </svg>
      <% :clipboard -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          class={margin_for_left_text<>" -mr-1 w-5 h-5"}
        >
          <path
            fill-rule="evenodd"
            d="M10.5 3A1.501 1.501 0 009 4.5h6A1.5 1.5 0 0013.5 3h-3zm-2.693.178A3 3 0 0110.5 1.5h3a3 3 0 012.694 1.678c.497.042.992.092 1.486.15 1.497.173 2.57 1.46 2.57 2.929V19.5a3 3 0 01-3 3H6.75a3 3 0 01-3-3V6.257c0-1.47 1.073-2.756 2.57-2.93.493-.057.989-.107 1.487-.15z"
            clip-rule="evenodd"
          />
        </svg>
      <% :markdown -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 208 128"
          fill="currentColor"
          class={margin_for_left_text<>" -mr-1 w-5 h-5"}
        >
          <path
            fill-rule="evenodd"
            d="M30 98V30h20l20 25 20-25h20v68H90V59L70 84 50 59v39zm125 0l-30-33h20V30h20v35h20z"
          />
        </svg>
      <% :locked -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          class={margin_for_left_text<>" -mr-1 w-5 h-5"}
        >
          <path
            fill-rule="evenodd"
            d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
            clip-rule="evenodd"
          />
        </svg>
      <% :unlocked -> %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          class={margin_for_left_text<>" -mr-1 w-5 h-5"}
        >
          <path
            fill-rule="evenodd"
            d="M14.5 1A4.5 4.5 0 0010 5.5V9H3a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-1.5V5.5a3 3 0 116 0v2.75a.75.75 0 001.5 0V5.5A4.5 4.5 0 0014.5 1z"
            clip-rule="evenodd"
          />
        </svg>
    <% end %>
    """
  end

  def copiable(assigns) do
    ~H"""
    <li class="flex flex-nowrap my-2">
      <button
        :if={@type != :hidden}
        type="button"
        disabled={not @enabled}
        class="inline-flex items-center rounded-l-md border border-r-0 border-gray-300 bg-gray-50 px-3 text-gray-500 sm:text-sm"
        phx-click={if @enabled, do: JS.dispatch("live-secret:clipcopy", to: "##{@id}")}
      >
        <.action_icon has_text={false} id={:clipboard} />
      </button>

      <% input_class =
        "font-mono block w-full min-w-0 flex-1 rounded-none rounded-r-md border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm text-gray-700 hover:text-gray-900" %>

      <%= if @ignore do %>
        <div phx-update="ignore" id={@id <> "-div-for-ignore"} class="w-full">
          <input
            type={@type}
            id={@id}
            disabled
            class={input_class}
            value={@value}
            placeholder={@placeholder}
          />
        </div>
      <% else %>
        <input
          type={@type}
          id={@id}
          disabled
          class={input_class}
          value={@value}
          placeholder={@placeholder}
        />
      <% end %>
    </li>
    """
  end

  slot :title, required: true
  slot :content

  def section_header(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl pt-4 px-4">
      <h2 class="text-lg font-bold leading-tight tracking-tight text-gray-900">
        {render_slot(@title)}
      </h2>
      <span class="inline-flex text-sm text-gray-500">{render_slot(@content)}</span>
    </div>
    """
  end

  def decrypt_modal(assigns) do
    ~H"""
    <div
      id="decrypt-modal"
      class="relative z-10"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <!--
      Background backdrop, show/hide based on modal state.

      Entering: "ease-out duration-300"
        From: "opacity-0"
        To: "opacity-100"
      Leaving: "ease-in duration-200"
        From: "opacity-100"
        To: "opacity-0"
    -->
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

      <div class="fixed inset-0 z-10 overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center">
          <!--
          Modal panel, show/hide based on modal state.

          Entering: "ease-out duration-300"
            From: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            To: "opacity-100 translate-y-0 sm:scale-100"
          Leaving: "ease-in duration-200"
            From: "opacity-100 translate-y-0 sm:scale-100"
            To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
        -->
          <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full md:w-2/3 sm:p-6">
            <div>
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
                <!-- Heroicon name: outline/lock-open -->
                <svg
                  class="h-6 w-6 text-red-600"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path d="M18 1.5c2.9 0 5.25 2.35 5.25 5.25v3.75a.75.75 0 01-1.5 0V6.75a3.75 3.75 0 10-7.5 0v3a3 3 0 013 3v6.75a3 3 0 01-3 3H3.75a3 3 0 01-3-3v-6.75a3 3 0 013-3h9v-3c0-2.9 2.35-5.25 5.25-5.25z" />
                </svg>
              </div>
              <div id="passphraseform" class="mt-3 text-center sm:mt-5" phx-update="ignore">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id="modal-title">
                  Enter the passphrase
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    Paste the passphrase into this box and press 'Decrypt'. The secret content will be shown if the passphrase is correct.
                  </p>
                </div>
                <div class="pt-2" phx-update="ignore" id="passphrase-div-for-ignore">
                  <input
                    type="text"
                    name="passphrase"
                    id="passphrase"
                    class="block w-full rounded-full border-gray-300 px-4 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    placeholder="Passphrase"
                    autocomplete="off"
                    phx-hook="SubmitDecrypt"
                  />
                </div>
              </div>
              <div id="successmessage" class="mt-3 text-center sm:mt-5 hidden" phx-update="ignore">
                <h3 class="text-lg font-medium leading-6 text-gray-900">
                  Success!
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">
                    When you leave this window, the content is gone forever.
                  </p>
                </div>
              </div>
            </div>

            <div id="ciphertext-div-for-ignore" phx-update="ignore">
              <input
                type="hidden"
                id="ciphertext"
                value={if is_nil(@secret.content), do: nil, else: :base64.encode(@secret.content)}
              />
            </div>
            <div id="iv-div-for-ignore" phx-update="ignore">
              <input
                type="hidden"
                id="iv"
                value={if is_nil(@secret.iv), do: nil, else: :base64.encode(@secret.iv)}
              />
            </div>
            <div id="decryptionfailure-div-for-ignore">
              <div id="decryptionfailure-container" class="hidden text-center pt-1">
                <div class="inline-flex">
                  <div class="block pr-2">
                    <p class="text-md text-gray-700">Incorrect passphrase - try again</p>
                  </div>
                  <span
                    class="hidden inline-flex items-center rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-800"
                    id="fail-counter"
                    phx-hook="OnIncorrectPassphrase"
                  >
                    0
                  </span>
                </div>
              </div>
            </div>
            <div id="cleartext-div-for-ignore" phx-update="ignore">
              <div id="cleartext-container" class="hidden text-center">
                <textarea
                  id="cleartext"
                  readonly
                  class="block w-full resize-none rounded-md border-yellow-400 bg-gray-100 placeholder-gray-500 ring-0 font-mono"
                />
                <div class="p-4 w-full flex justify-center items-center align-center">
                  <button
                    type="button"
                    class="text-blue-700 bg-blue-100 hover:bg-blue-200 focus:ring-blue-500 inline-flex items-center justify-center rounded-md border border-transparent px-4 py-2 font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 sm:text-sm "
                    phx-click={JS.dispatch("live-secret:clipcopy", to: "#cleartext")}
                  >
                    Copy to clipboard <.action_icon has_text={true} id={:clipboard} />
                  </button>
                </div>
              </div>
            </div>

            <.form :let={f} for={@changeset} phx-change="burn" autocomplete="off">
              {hidden_input(f, :burn_key, id: "burnkey")}
            </.form>

            <div
              id="decrypt-btns-div-for-ignore"
              phx-update="ignore"
              class="mt-5 sm:mt-6 sm:grid sm:grid-flow-row-dense sm:grid-cols-2 sm:gap-3"
            >
              <button
                type="button"
                id="decrypt-btn"
                class="inline-flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-2 sm:text-sm"
                phx-click={JS.dispatch("live-secret:decrypt-secret")}
              >
                Decrypt
              </button>
              <button
                type="button"
                id="close-btn"
                class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:col-start-1 sm:mt-0 sm:text-sm"
                phx-click={JS.hide(to: "#decrypt-modal") |> JS.show(to: "#decrypt-instructions")}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def help(assigns) do
    ~H"""
    <div class="p-4 flex-1">
      <div class="flex items-center space-x-3">
        <h3 class="text-sm font-medium text-gray-900">What is this?</h3>
      </div>
      <p class="pt-1 mt-1 text-sm text-gray-500">
        LiveSecret allows two people to securely exchange
        <a class="underline" href="https://en.wikipedia.org/wiki/Shared_secret">shared secrets</a>
        using <a class="underline" href="https://en.wikipedia.org/wiki/End-to-end_encryption">end-to-end encryption</a>.
        <%= if @live_action == :receiver do %>
          Since you're here it means that someone you trust sent you a link and a passphrase.
          <p class="pt-1 mt-1 text-sm text-gray-500">
            When the author of the secret is ready, they will unlock your page, and you will be prompted for the passphrase.
          </p>
        <% end %>
      </p>

      <%= if @live_action == :create do %>
        <div class="pt-4 flex items-center space-x-3">
          <h3 class="text-sm font-medium text-gray-900">How does it work?</h3>
        </div>
        <p class="pt-1 mt-1 text-sm text-gray-500">
          <ol type="1" class="list-decimal ml-8">
            <li class="pt-1 mt-1 text-sm text-gray-500">Enter secret data into the box above.</li>
            <li class="pt-1 mt-1 text-sm text-gray-500">
              Press Encrypt. The data is encrypted locally before being sent to the server. The passphrase stays with you.
            </li>
            <li class="pt-1 mt-1 text-sm text-gray-500">
              You send the provided instructions to the recipient out-of-band.
            </li>
            <li class="pt-1 mt-1 text-sm text-gray-500">
              Unlock the intended recipient when you see they have arrived on the page.
            </li>
          </ol>
        </p>
      <% end %>

      <div class="pt-4 flex items-center space-x-3">
        <h3 class="text-sm font-medium text-gray-900">Can I learn more?</h3>
      </div>
      <p class="pt-1 mt-1 text-sm text-gray-500">
        More details at the
        <a class="underline" href="https://github.com/JesseStimpson/livesecret">LiveSecret</a>
        GitHub project.
      </p>
    </div>
    """
  end

  defp build_external_url("https", host, 443, path) do
    "https://#{host}#{path}"
  end

  defp build_external_url(scheme, host, port, path) do
    "#{scheme}://#{host}:#{port}#{path}"
  end
end
