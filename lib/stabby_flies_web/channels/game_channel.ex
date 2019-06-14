defmodule StabbyFliesWeb.GameChannel do
  @moduledoc """
  Description about the use of this Module
  """
  use StabbyFliesWeb, :channel
  require Logger

  alias StabbyFlies.{Game, Game, Player}

  def handle_in("connect", payload, socket) do
    {:noreply, socket}
  end

  def join("game", payload, socket) do
    unique_id = "Fly-#{socket.id}"

    Logger.debug("Joined Lobby #{payload["nickname"]}")

    socket =
      socket
      |> assign(:unique_id, unique_id)
      |> assign(:nickname, payload["nickname"])

    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_in("shout", payload, socket) do
    # Disabled until input is sanitized
    StabbyFlies.Message.changeset(%StabbyFlies.Message{}, payload) |> StabbyFlies.Repo.insert()
    response = payload |> Map.put(:socket_id, socket.assigns.unique_id)
    broadcast(socket, "shout", response)
    {:noreply, socket}
  end

  def handle_in("move", %{"moving" => moving}, socket) do
    Game.set_player_moving(socket.assigns.unique_id, moving)

    {:noreply, socket}
  end

  def handle_in("move", _, socket) do
    {:noreply, socket}
  end

  def handle_in("stab", payload, socket) do
    {stabbed?, hit_players} = Game.player_stabs(socket.assigns.unique_id)

    if stabbed? == true,
      do:
        broadcast(socket, "stab", %{
          socket_id: socket.assigns.unique_id,
          hit_players_data: hit_players
        })

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    IO.puts("PLAYER TERMINATED")
    Game.leave_game(socket.assigns.unique_id)
    broadcast(socket, "disconnect", %{socket_id: socket.assigns.unique_id})
  end

  def handle_info(:after_join, socket) do
    Game.join_game(socket.assigns.unique_id, socket.assigns.nickname)
    new_player = Game.player_state(socket.assigns.unique_id)
    # name = elem(eh, 1)

    # new_player = Game.add_player("#{socket.assigns.nickname}", socket.id)

    broadcast(socket, "connect", %{new_player: new_player, players: Game.get_players()})

    push(socket, "initialize", %{
      new_player: new_player
    })

    # Disabled for now
    # StabbyFlies.Message.get_messages()
    # |> Enum.each(fn msg -> push(socket, "shout", %{
    #     name: msg.name,
    #     message: msg.message,
    #   }) end)
    {:noreply, socket}
  end
end
