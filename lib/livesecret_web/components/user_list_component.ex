defmodule LiveSecretWeb.UserListComponent do
  use Phoenix.Component

  alias LiveSecretWeb.{ComponentUtil, ActiveUser}

  def view(assigns) do
    ~H"""
    <div class="py-4">
      <div class="overflow-hidden bg-white shadow rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <%= for {_user_id, active_user} <- sort_users(@users, @self) do %>
            <li>
              <div class="block sm:flex items-center px-4 py-4 sm:px-6">
                <div class="flex min-w-0 flex-1 items-center">
                  <div class="flex-shrink-0">
                    <span class="relative inline-block">
                      <span class="inline-block h-12 w-12 overflow-hidden rounded-full bg-gray-100">
                        <svg
                          class="h-full w-full text-gray-300"
                          fill="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path d="M24 20.993V24H0v-2.996A14.977 14.977 0 0112.004 15c4.904 0 9.26 2.354 11.996 5.993zM16.002 8.999a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                      </span>
                      <.dot active_user={active_user} />
                    </span>
                  </div>
                  <div class="min-w-0 flex-1 px-4">
                    <div>
                      <.user_role self={@self} active_user={active_user} />

                      <p class="mt-2 flex items-center text-sm text-gray-500">
                        <!-- Heroicon name: mini/identification -->
                        <svg
                          class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M1 6a3 3 0 013-3h12a3 3 0 013 3v8a3 3 0 01-3 3H4a3 3 0 01-3-3V6zm4 1.5a2 2 0 114 0 2 2 0 01-4 0zm2 3a4 4 0 00-3.665 2.395.75.75 0 00.416 1A8.98 8.98 0 007 14.5a8.98 8.98 0 003.249-.604.75.75 0 00.416-1.001A4.001 4.001 0 007 10.5zm5-3.75a.75.75 0 01.75-.75h2.5a.75.75 0 010 1.5h-2.5a.75.75 0 01-.75-.75zm0 6.5a.75.75 0 01.75-.75h2.5a.75.75 0 010 1.5h-2.5a.75.75 0 01-.75-.75zm.75-4a.75.75 0 000 1.5h2.5a.75.75 0 000-1.5h-2.5z"
                            clip-rule="evenodd"
                          />
                        </svg>
                        <span class="truncate text-small"><code>{active_user.name}</code></span>
                      </p>
                      <p class="mt-2 flex items-center text-sm text-gray-500">
                        <!-- Heroicon name: mini/clock -->
                        <svg
                          class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M10 18a8 8 0 100-16 8 8 0 000 16zm.75-13a.75.75 0 00-1.5 0v5c0 .414.336.75.75.75h4a.75.75 0 000-1.5h-3.25V5z"
                            clip-rule="evenodd"
                          />
                        </svg>
                        <span class="truncate text-small">
                          <.time_info active_user={active_user} />
                        </span>
                      </p>
                    </div>
                    <div class="block">
                      <!-- more things can go here in the middle -->
                    </div>
                  </div>
                </div>
                <.user_badge
                  self={@self}
                  live_action={@live_action}
                  active_user={active_user}
                  force_disable={not is_nil(@burned_at)}
                />
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  User role states:
  1. Admin
      live_action: :admin
      connected?: true
  2. Recipient
      live_action: :receiver
      connected?: true
  3. Former {Admin|Recipient}
      live_action: :admin|:receiver
      connected?: false

  The string "(me)" is added to the user role for the current_user.
  """
  def user_role(assigns) do
    ~H"""
    <p class="truncate text-sm font-medium text-indigo-600">
      <%= case {@active_user.live_action, ActiveUser.connected?(@active_user)} do %>
        <% {_, true} -> %>
          {ComponentUtil.render_live_action(@active_user.live_action, nil)}
        <% {_, false} -> %>
          Former {ComponentUtil.render_live_action(@active_user.live_action, nil)}
      <% end %>
      <%= if @self == @active_user.id do %>
        (me)
      <% end %>
    </p>
    """
  end

  @doc """
  Time info states:
  1. Joined at:
      connected?: true
  2. Left at:
      connected? false
  """
  def time_info(assigns) do
    ~H"""
    <%= if ActiveUser.connected?(@active_user) do %>
      Joined: <time datetime={@active_user.joined_at}>{@active_user.joined_at}</time>
    <% else %>
      Left: <time datetime={@active_user.left_at}>{@active_user.left_at}</time>
    <% end %>
    """
  end

  @doc """
  Dot states:
  1. Green:
      connected?: true
  2. Gray:
      connected?: false
  """
  def dot(assigns) do
    ~H"""
    <%= if ActiveUser.connected?(@active_user) do %>
      <span class="absolute bottom-0 right-0 block h-3 w-3 rounded-full bg-green-300 ring-2 ring-white">
      </span>
    <% else %>
      <span class="absolute bottom-0 right-0 block h-3 w-3 rounded-full bg-gray-300 ring-2 ring-white">
      </span>
    <% end %>
    """
  end

  @doc """
  Badge states:
  1. Locked/Waiting...:
      au.live_action: :receiver
      state: :locked
      connected?: true
  2. Unlocked
      au.live_action: :receiver
      state: :unlocked
      connected?: true|false
  3. Revealed:
      au.live_action: :receiver
      state: :revealed
      connected?: true|false
      OR
      au.live_action: :admin
      connected?: false
  4. Left
      au.live_action: :receiver
      locked: true
      connected?: false
  5. Managing:
      au.live_action: admin
  """
  def user_badge(assigns) do
    ~H"""
    <div class="inline-flex sm:block justify-center items-center pt-4 sm:p-0 w-full sm:w-fit">
      <%= case {@active_user.live_action, @active_user.state, ActiveUser.connected?(@active_user)} do %>
        <% {:receiver, :locked, true} -> %>
          <% enabled = not (@force_disable or @live_action != :admin) %>
          <.badge
            enabled={enabled}
            icon={:lock}
            phx_click={if enabled and @live_action == :admin, do: "unlock", else: ""}
            phx_value_id={@active_user.id}
            text={if @active_user.id == @self, do: "Waiting...", else: "Locked"}
          />
        <% {:receiver, :locked, false} -> %>
          <.badge enabled={false} icon={:shield} text="Left" />
        <% {:receiver, :unlocked, _} -> %>
          <.badge enabled={false} icon={:unlock} text="Unlocked" />
        <% {:receiver, :revealed, _} -> %>
          <.badge enabled={false} icon={:bolt} text="Revealed" />
        <% {:admin, _, true} -> %>
          <.badge enabled={false} icon={:beaker} text="Managing" />
        <% {:admin, _, false} -> %>
          <.badge enabled={false} icon={:bolt} text="Revealed" />
      <% end %>
    </div>
    """
  end

  attr :enabled, :boolean, default: true
  attr :phx_click, :string, default: nil
  attr :phx_value_id, :string, default: nil
  attr :icon, :atom
  attr :text, :string, required: true
  attr :class, :string, default: "border border-gray-300 shadow-sm hover:bg-gray-50"

  def badge(assigns) do
    ~H"""
    <button
      type="button"
      disabled={not @enabled}
      class={[
        "inline-flex items-center rounded-full bg-white px-2.5 py-0.5 text-sm font-sm leading-5 text-gray-700",
        @class
      ]}
      phx-click={@phx_click}
      phx-value-id={@phx_value_id}
    >
      <.badge_icon id={@icon} />
      {@text}
    </button>
    """
  end

  defp badge_icon(assigns) do
    ~H"""
    <% class = "mr-1.5 h-5 w-5 flex-shrink-0" %>
    <%= case @id do %>
      <% :lock -> %>
        <!-- Heroicon name: mini/lock -->
        <svg
          class={"#{class} text-green-400"}
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
          class={"#{class} text-red-400"}
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
      <% :bolt -> %>
        <svg
          class={"#{class} text-yellow-400"}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M11.983 1.907a.75.75 0 00-1.292-.657l-8.5 9.5A.75.75 0 002.75 12h6.572l-1.305 6.093a.75.75 0 001.292.657l8.5-9.5A.75.75 0 0017.25 8h-6.572l1.305-6.093z" />
        </svg>
      <% :shield -> %>
        <!-- Heroicon name: mini/shield-check -->
        <svg
          class={"#{class} text-gray-400"}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M9.661 2.237a.531.531 0 01.678 0 11.947 11.947 0 007.078 2.749.5.5 0 01.479.425c.069.52.104 1.05.104 1.59 0 5.162-3.26 9.563-7.834 11.256a.48.48 0 01-.332 0C5.26 16.564 2 12.163 2 7c0-.538.035-1.069.104-1.589a.5.5 0 01.48-.425 11.947 11.947 0 007.077-2.75zm4.196 5.954a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
            clip-rule="evenodd"
          />
        </svg>
      <% :beaker -> %>
        <svg
          class={"#{class} text-pink-400"}
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fill-rule="evenodd"
            d="M8.5 3.528v4.644c0 .729-.29 1.428-.805 1.944l-1.217 1.216a8.75 8.75 0 013.55.621l.502.201a7.25 7.25 0 004.178.365l-2.403-2.403a2.75 2.75 0 01-.805-1.944V3.528a40.205 40.205 0 00-3 0zm4.5.084l.19.015a.75.75 0 10.12-1.495 41.364 41.364 0 00-6.62 0 .75.75 0 00.12 1.495L7 3.612v4.56c0 .331-.132.649-.366.883L2.6 13.09c-1.496 1.496-.817 4.15 1.403 4.475C5.961 17.852 7.963 18 10 18s4.039-.148 5.997-.436c2.22-.325 2.9-2.979 1.403-4.475l-4.034-4.034A1.25 1.25 0 0113 8.172v-4.56z"
            clip-rule="evenodd"
          />
        </svg>
    <% end %>
    """
  end

  defp sort_users(users, top_user_id) do
    users
    |> Enum.to_list()
    |> Enum.sort(fn
      {^top_user_id, _}, {_, _} -> true
      {_, _}, {^top_user_id, _} -> false
      {ida, %{left_at: nil}}, {idb, %{left_at: nil}} -> ida <= idb
      {_, %{left_at: nil}}, {_, %{left_at: _}} -> true
      {_, %{left_at: _}}, {_, %{left_at: nil}} -> false
      {ida, _}, {idb, _} -> ida <= idb
    end)
  end
end
