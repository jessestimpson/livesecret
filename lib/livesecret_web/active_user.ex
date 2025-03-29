defmodule LiveSecretWeb.ActiveUser do
  defstruct id: nil,
            name: nil,
            live_action: nil,
            joined_at: nil,
            left_at: nil,
            # :locked | :unlocked | :revealed
            state: nil,
            decrypt_failure_count: 0

  def new(id, name, live_action, joined_at, state) do
    %__MODULE__{
      id: id,
      name: name,
      live_action: live_action,
      joined_at: joined_at,
      state: state
    }
  end

  def connected?(%__MODULE__{left_at: nil}), do: true
  def connected?(_), do: false
end
