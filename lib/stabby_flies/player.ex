defmodule StabbyFlies.Player do
  use GenServer

  defmodule State do
    defstruct ~w|name x y velx vely hp max_hp sword_rotation last_stab_time|a
  end

  # defguardp is_alive?(hp) when is_integer(hp) and hp > 0

  # def alive?(%{hp: hp}) when is_alive?(hp), do: true
  # def alive?(%{}), do: false

  # def decrease_hp(%{hp: hp} = player, quantity) do
  #   %{player | hp: hp - quantity}
  # end

  # def move_right(%{velx: velx, hp: hp} = player, quantity \\ 1) do
  #   # when is_alive?(hp) do
  #   %{player | velx: quantity}
  # end

  # def move_left(%{velx: velx, hp: hp} = player, quantity \\ 1) do
  #   %{player | velx: -1 * quantity}
  # end

  # def move_up(%{vely: vely, hp: hp} = player, quantity \\ 1) do
  #   %{player | vely: -1 * quantity}
  # end

  # def move_down(%{vely: vely, hp: hp} = player, quantity \\ 1) do
  #   %{player | vely: 1 * quantity}
  # end

  def start_link(opts) do
    defaults = [
      name: "NAMELESS",
      x: start_x(),
      y: start_y(),
      velx: 0,
      vely: 0,
      hp: 1,
      max_hp: 1,
      sword_rotation: 0
    ]

    init_fly = Keyword.merge(defaults, opts)

    name = Keyword.get(init_fly, :name)
    x = Keyword.get(init_fly, :x)
    y = Keyword.get(init_fly, :y)
    velx = Keyword.get(init_fly, :velx)
    vely = Keyword.get(init_fly, :vely)
    hp = Keyword.get(init_fly, :hp)
    max_hp = Keyword.get(init_fly, :max_hp)
    sword_rotation = Keyword.get(init_fly, :sword_rotation)

    GenServer.start_link(
      __MODULE__,
      %State{
        name: name,
        x: x,
        y: y,
        hp: hp,
        velx: velx,
        vely: vely,
        max_hp: max_hp,
        sword_rotation: sword_rotation,
        last_stab_time: Time.add(Time.utc_now(), -1)
      },
      name: via_tuple(name)
    )
  end

  def init(init_arg), do: {:ok, init_arg}
  def state(pid), do: GenServer.call(pid, :state)
  def take_damage(pid, amount), do: GenServer.call(pid, {:take_damage, amount})
  def update_position(pid), do: GenServer.call(pid, :update_position)
  def can_stab(pid), do: GenServer.call(pid, :can_stab)
  def reset_stab_cooldown(pid), do: GenServer.call(pid, :reset_stab_cooldown)
  def stop(pid), do: GenServer.stop(via_tuple(pid))

  def handle_call(:can_stab, _from, %State{last_stab_time: last_stab_time} = state) do
    stab_cooldown = 300
    now = Time.utc_now()

    can_stab = Time.diff(now, last_stab_time, :millisecond) >= stab_cooldown
    {:reply, can_stab, state}
  end

  def handle_call(:reset_stab_cooldown, _from, state) do
    new_state = Map.merge(state, %{last_stab_time: Time.utc_now()})
    {:reply, new_state, new_state}
  end

  def handle_call(:state, _from, %State{} = state) do
    {:reply, state, state}
  end

  def handle_call({:take_damage, amount}, _from, %State{hp: hp} = state) do
    new_hp = if hp - amount < 0, do: 0, else: hp - amount
    new_state = Map.merge(state, %{hp: new_hp})
    {:reply, new_state, new_state}
  end

  def handle_call(:update_position, _from, %State{x: x, y: y, velx: velx, vely: vely} = state) do
    new_x = if x + velx < 0, do: 0, else: x + velx
    new_x = if new_x + velx >= 3000, do: 3000, else: new_x + velx

    new_y = if y + vely < -100, do: -100, else: y + vely
    new_y = if new_y + vely >= 270, do: 270, else: new_y + vely

    new_state = Map.merge(state, %{x: new_x, y: new_y})
    {:reply, new_state, new_state}
  end

  defp start_y do
    Enum.random(-100..270)
  end

  defp start_x do
    Enum.random(0..3000)
  end

  defp via_tuple(player_name) do
    {:via, Registry, {Registry.PlayersServer, player_name}}
  end
end
