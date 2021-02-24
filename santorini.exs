defmodule Game do

  # Rows are arrays, columns are indices within arrays
  def empty_board() do
    r = [0, 0, 0, 0, 0]
    [r,r,r,r,r]
  end

  def initial_state(players) do
    %{ turn: 0, spaces: empty_board(), players: players}
  end

  def advance_turn(state) do

  end

  def all_tokens(s) do
    Enum.at(s[:players], 0) ++ Enum.at(s[:players], 1)
  end

  # returns true if token is allowed to move into specified space
  # s for state. does not check if token is one space away
  def can_move?(s, token, space) do
    # elixir question: is there a better way to test
    is_token_free = Enum.reduce_while(all_tokens(s), true, fn token, acc ->
      if acc do
        IO.inspect space
        IO.inspect token
        {:cont, space == token }
      else
        {:halt, false}
      end
    end)
    increase_is_max_one = (space_height(s, space) - space_height(s, token)) <= 1
    is_not_complete_tower = space_height(s, space) < 4

    IO.inspect is_token_free
    IO.inspect increase_is_max_one
    IO.inspect is_not_complete_tower
    is_token_free && increase_is_max_one && is_not_complete_tower
  end

  def space_height(state, space) do
    row = Enum.at(state[:spaces], Enum.at(space, 0) - 1)
    Enum.at(row, Enum.at(space, 1) - 1)
  end
end


defmodule GameTest do
  use ExUnit.Case

  test "can_move" do
    players = [[[2,3],[4,4]],[[2,5],[3,5]]]
    state = Game.initial_state(players)
    IO.inspect state
    assert Game.can_move?(state, [2,3], [4,4]) == false
    assert Game.can_move?(state, [2,3], [4,5]) == true
  end
end

ExUnit.start()
