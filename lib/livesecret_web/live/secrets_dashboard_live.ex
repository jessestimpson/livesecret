defmodule LiveSecretWeb.SecretsDashboardPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder, refresher?: false
  alias LiveSecretWeb.Presence
  alias LiveSecret.Secret
  import Ecto.Query

  @impl true
  def menu_link(_, _) do
    {:ok, "Secrets"}
  end

  @impl true
  def mount(_params, _session, socket) do
    query = from s in Secret, order_by: [desc: s.inserted_at]

    {:ok,
     socket
     |> put_private(:tenant, Presence.tenant_from_socket(socket))
     |> LiveSecret.sync_secrets(:secrets, query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.table page={@page} title="Secrets" rows={@secrets}>
      <:col field={:id} />
      <:col field={:label} />
      <:col field={:burned_at} />
      <:col field={:expires_at} />
      <:col field={:live?} />
      <:col field={:inserted_at} />
    </.table>
    """
  end

  attr :page, Phoenix.LiveDashboard.PageBuilder, required: true, doc: "Dashboard page"

  attr :rows, :list, required: true, doc: "Rows of data"

  slot :col, required: true, doc: "Columns for the table" do
    attr :field, :atom, required: true, doc: "Identifier for the column"

    attr :header, :string,
      doc: "Label to show in the current column. Default value is calculated from `:field`."
  end

  attr :title, :string, required: true, doc: "The title of the table."

  attr :hint, :string, default: nil, doc: "A textual hint to show close to the title."
  attr :dom_id, :string, default: nil, doc: "id attribute for the HTML the main tag."

  defp table(assigns) do
    ~H"""
    <div id="secrets" class="tabular">
      <Phoenix.LiveDashboard.PageBuilder.card_title title={@title} hint={@hint} />
      <div class="card tabular-card mb-4 mt-4">
        <div class="card-body p-0">
          <div class="dash-table-wrapper">
            <table class="table table-hover mt-0 dash-table">
              <thead>
                <tr>
                <th :for={column <- @col}>
                {column[:header] || column[:field]}
                </th>
                </tr>
              </thead>
              <tbody>
                <tr :for={row <- @rows}>
                  <td :for={column <- @col}>
                    {Map.get(row, column.field) |> to_string()}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
