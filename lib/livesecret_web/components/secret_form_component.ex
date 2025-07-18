defmodule LiveSecretWeb.SecretFormComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use PhoenixHTMLHelpers

  def create(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@changeset}
      action="#"
      class="relative"
      id="secret-form"
      phx-change="validate"
      phx-submit="create"
      phx-hook="CreateSecret"
      autocomplete="off"
    >
      <div class="overflow-hidden rounded-lg border border-gray-300 shadow-sm focus-within:border-indigo-500 focus-within:ring-1 focus-within:ring-indigo-500">
        <div class="flex">
          <input
            phx-feedback-for="label"
            type="text"
            name={f[:label].name}
            class="flex text-xs font-medium text-gray-700 pt-2 px-2 border-0 focus:ring-0"
            id={f[:label].id}
            value={Phoenix.HTML.Form.normalize_value("text", f[:label].value)}
            placeholder="Content"
          />
        </div>
        <div phx-update="ignore" id="cleartext-div-for-ignore">
          <textarea
            id="cleartext"
            class="h-24 sm:h-64 pt-3 block w-full resize-y border-0 py-0 placeholder-gray-500 focus:ring-0 font-mono"
            placeholder="Put your secret information here..."
          />
        </div>
        {hidden_input(f, :content, id: "ciphertext")}
        {hidden_input(f, :iv, id: "iv")}
        {hidden_input(f, :burn_key, id: "burnkey")}
        {hidden_input(f, :initiator, id: "initiator")}
        <!-- Spacer element to match the height of the toolbar -->
        <.spacer />
      </div>

      <div class="absolute inset-x-px bottom-0">
        <!-- Actions: These are just examples to demonstrate the concept, replace/wire these up however makes sense for your project. -->
        <div class="flex flex-nowrap justify-end space-x-2 py-2 px-2 sm:px-3">
          <.param_choice
            f={f}
            changeset={@changeset}
            list={@modes}
            field={:mode}
            icon={%{live: :lock, async: :unlock}}
          />
          <.param_choice
            f={f}
            changeset={@changeset}
            list={@durations}
            field={:duration}
            icon={:calendar}
          />
        </div>

        <div class="flex items-center justify-between space-x-3 border-t border-gray-200 px-2 py-2 sm:px-3">
          <.passphrase_entry />
          <.create_button />
        </div>
      </div>
    </.form>
    """
  end

  def param_choice(assigns) do
    ~H"""
    <div class="flex-shrink-0">
      <label id={"listbox-label-#{@field}"} class="sr-only"> Add an expiration </label>
      <div class="relative">
        <button
          type="button"
          class="relative inline-flex items-center whitespace-nowrap rounded-full bg-gray-50 py-2 px-2 text-sm font-medium text-gray-500 hover:bg-gray-100 sm:px-3"
          aria-haspopup="listbox"
          aria-expanded="true"
          aria-labelledby={"listbox-label-#{@field}"}
          phx-click={JS.toggle(to: "##{@field}-popover")}
        >
          <% choice = Ecto.Changeset.fetch_field!(@changeset, @field) %>
          <.toolbar_icon id={@icon} choice={choice} />
          <span class="hidden truncate sm:ml-2 sm:block"><.choice_text v={choice} /></span>
          {hidden_input(@f, @field, id: "#{@field}")}
        </button>

        <ul
          id={"#{@field}-popover"}
          class="hidden absolute right-0 z-10 mt-1 max-h-56 w-auto overflow-auto rounded-lg bg-white py-3 text-base shadow ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"
          tabindex="-1"
          role="listbox"
          aria-labelledby={"listbox-label-#{@field}"}
          aria-activedescendant="listbox-option-0"
          phx-click-away={JS.hide(to: "##{@field}-popover")}
        >
          <li
            :for={item <- @list}
            class="bg-white relative cursor-default select-none py-2 px-3 hover:bg-gray-100"
            role="option"
            phx-click={
              JS.hide(to: "##{@field}-popover")
              |> JS.dispatch("live-secret:select-choice",
                to: "##{@field}",
                detail: %{"value" => item}
              )
            }
          >
            <div class="flex items-center">
              <span class="block truncate font-medium"><.choice_text v={item} /></span>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def toolbar_icon(assigns) do
    ~H"""
    <%= case @id do %>
      <% :calendar -> %>
        <svg
          class="h-5 w-5 flex-shrink-0 text-gray-300 sm:-ml-1"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M5.75 2a.75.75 0 01.75.75V4h7V2.75a.75.75 0 011.5 0V4h.25A2.75 2.75 0 0118 6.75v8.5A2.75 2.75 0 0115.25 18H4.75A2.75 2.75 0 012 15.25v-8.5A2.75 2.75 0 014.75 4H5V2.75A.75.75 0 015.75 2zm-1 5.5c-.69 0-1.25.56-1.25 1.25v6.5c0 .69.56 1.25 1.25 1.25h10.5c.69 0 1.25-.56 1.25-1.25v-6.5c0-.69-.56-1.25-1.25-1.25H4.75z"
            clip-rule="evenodd"
          />
        </svg>
      <% :lock -> %>
        <svg
          class="h-5 w-5 flex-shrink-0 text-gray-300 sm:-ml-1"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
            clip-rule="evenodd"
          />
        </svg>
      <% :unlock -> %>
        <svg
          class="h-5 w-5 flex-shrink-0 text-gray-300 sm:-ml-1"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M14.5 1A4.5 4.5 0 0010 5.5V9H3a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-1.5V5.5a3 3 0 116 0v2.75a.75.75 0 001.5 0V5.5A4.5 4.5 0 0014.5 1z"
            clip-rule="evenodd"
          />
        </svg>
      <% map when is_map(map) -> %>
        <.toolbar_icon id={map[@choice]} choice={@choice} />
    <% end %>
    """
  end

  def spacer(assigns) do
    ~H"""
    <div aria-hidden="true">
      <div class="py-2">
        <div class="h-9"></div>
      </div>
      <div class="h-px"></div>
      <div class="py-2">
        <div class="py-px">
          <div class="h-9"></div>
        </div>
      </div>
    </div>
    """
  end

  def passphrase_entry(assigns) do
    ~H"""
    <div class="flex w-full">
      <div class="w-full">
        <label class="block text-xs font-medium text-gray-700">Passphrase</label>
        <div phx-update="ignore" id="passphrase-div-for-ignore">
          <input
            type="text"
            ,
            id="passphrase"
            class="block w-full border-0 text-sm font-medium placeholder-gray-500 focus:ring-0 font-mono"
            placeholder="(generated)"
          />
        </div>
      </div>
    </div>
    """
  end

  def create_button(assigns) do
    ~H"""
    <div class="isolate inline-flex -space-x-px rounded-md shadow-xs">
      <button
        type="submit"
        value={:encrypt}
        class={["relative inline-flex items-center",
        "rounded-l-md px-4 py-2",
        "ring-1 ring-gray-300",
        "border border-transparent",
        "bg-indigo-600 text-sm font-semibold text-white shadow-sm",
        "hover:bg-indigo-700",
        "focus:bg-indigo-500"]}
      >
        <.choice_text v={:encrypt} />
      </button>
      <button
        type="button"
        class={["relative inline-flex items-center",
        "rounded-r-md px-2 py-2",
        "ring-1 ring-gray-300",
        "border border-transparent",
        "bg-indigo-600 text-sm font-semibold text-white shadow-sm",
        "hover:bg-indigo-700"]}
        phx-click={JS.toggle(to: "#create-popover")}
      >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="h-4 w-4 size-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
      </svg>
      </button>
      <ul
        id={"create-popover"}
        class={["hidden absolute right-10 z-10 mt-1 max-h-56 w-auto",
        "overflow-auto rounded-lg bg-white py-3",
        "text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"]}
        tabindex="-1"
        role="listbox"
        aria-labelledby={"listbox-label-create"}
        aria-activedescendant="listbox-option-0"
        phx-click-away={JS.hide(to: "#create-popover")}
      >
        <li
          :for={item <- [:encrypt, :request]}
          class="bg-white relative cursor-default select-none"
          role="option"
          phx-click={
            JS.hide(to: "#create-popover")
          }
        >
          <button type="submit" name={item} value={item} class={["flex items-center w-full py-2 px-3",
          "hover:ring-1 hover:ring-gray-300",
          "hover:bg-indigo-600 hover:text-white focus:text-white focus:bg-indigo-500"]}>
            <span class="block truncate font-medium"><.choice_text v={item} /></span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  def choice_text(assigns) do
    ~H"""
    <%= case @v do %>
      <% "1h" -> %>
        1 hour
      <% "1d" -> %>
        1 day
      <% "3d" -> %>
        3 days
      <% "1w" -> %>
        1 week
      <% :live -> %>
        Live
      <% :async -> %>
        Async
      <% :encrypt -> %>
        Encrypt
      <% :request -> %>
        Request
      <% _ -> %>
        error
    <% end %>
    """
  end
end
