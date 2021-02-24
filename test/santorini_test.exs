# defmodule SantoriniTest do
#   use ExUnit.Case
#   doctest Santorini

#   test "greets the world" do
#     assert Santorini.hello() == :world
#   end
# end

defmodule SantoriniTest do
  use ExUnit.Case
  # doctest Santorini

  test "adjacent_spaces" do
    assert Santorini.adjacent_spaces([1,1]) == [[1, 2], [2, 1], [2, 2]]
    assert Santorini.adjacent_spaces([1,2]) == [[1, 1], [1, 3], [2, 1], [2, 2], [2, 3]]
    assert Santorini.adjacent_spaces([4,4]) == [[3, 3], [3, 4], [3, 5], [4, 3], [4, 5], [5, 3], [5, 4], [5, 5]]
    assert Santorini.adjacent_spaces([5,5]) == [[4, 4], [4, 5], [5, 4]]
  end

  test "can_move" do
    players = [[[2,3],[4,4]],[[2,5],[3,5]]]
    state = Santorini.initial_state(players)
    # cannot move onto another token
    assert Santorini.can_move?(state, [2,3], [4,4]) == false
    assert Santorini.can_move?(state, [2,3], [4,5]) == true

    # cannot move more than one up (3 here is 4th row)
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 3, [1, 2, 3, 4, 0]))
    assert Santorini.can_move?(state, [2,3], [4,2]) == false # 0 -> 2
    assert Santorini.can_move?(state, [4,1], [4,2]) == true  # 1 -> 2
    assert Santorini.can_move?(state, [4,1], [4,3]) == false # 1 -> 3
    assert Santorini.can_move?(state, [4,3], [4,1]) == true # 3 -> 1
    assert Santorini.can_move?(state, [4,3], [4,4]) == false # 3 -> 4
  end

  test "can_build" do
    players = [[[2,3],[4,4]],[[2,5],[3,5]]]
    state = Santorini.initial_state(players)
    # cannot build on another token
    assert Santorini.can_build?(state, [4,4]) == false
    assert Santorini.can_build?(state, [4,5]) == true

    state = Map.put(state, :spaces, List.replace_at(state.spaces, 3, [1, 2, 3, 4, 0]))
    assert Santorini.can_build?(state, [4,2]) == true # 0 -> 2
    assert Santorini.can_build?(state, [4,2]) == true  # 1 -> 2
    assert Santorini.can_build?(state, [4,3]) == true # 1 -> 3
    assert Santorini.can_build?(state, [4,1]) == true # 3 -> 1
    assert Santorini.can_build?(state, [4,4]) == false # 3 -> 4
  end

  test "valid_spaces_to_move_into" do
    players = [[[1,1],[1,2]],[[3,3],[5,5]]]
    state = Santorini.initial_state(players)
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 0, [0, 1, 2, 3, 4]))
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 1, [3, 1, 2, 3, 4]))
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 2, [3, 1, 2, 3, 4]))
    # token occupies 1,2 ; too high to enter 2,1
    assert Santorini.valid_spaces_to_move_into(state, [1,1]) == [[2, 2]]
    assert Santorini.valid_spaces_to_move_into(state, [3,4]) == [[2, 3], [2, 4], [4, 3], [4, 4], [4, 5]]
  end

  test "valid_spaces_to_build_on" do
    players = [[[1,1],[1,2]],[[3,3],[5,5]]]
    state = Santorini.initial_state(players)
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 0, [0, 1, 2, 3, 4]))
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 1, [3, 1, 2, 3, 4]))
    state = Map.put(state, :spaces, List.replace_at(state.spaces, 2, [3, 1, 2, 3, 4]))
    # token occupies 1,2 ;
    assert Santorini.valid_spaces_to_build_on(state, [1,1]) == [[2, 1], [2, 2]]
    assert Santorini.valid_spaces_to_move_into(state, [3,4]) == [[2, 3], [2, 4], [4, 3], [4, 4], [4, 5]]
  end


  test "update_token" do
    players = [[[1,1],[1,2]],[[3,3],[5,5]]]
    state = Santorini.initial_state(players)

    new_players = [[[1,1],[1,3]],[[3,3],[5,5]]]

    assert Santorini.update_token(state, 0, [1,2], [1,3]) == Map.put(state, :players, new_players)
  end


  test "build_space_one" do
    state = Santorini.initial_state([])
    newstate = Map.put(state, :spaces, List.replace_at(state.spaces, 0, [1, 0, 0, 0, 0]))
    assert Santorini.build_space_one(state, [1,1]) == newstate

    anotherstate = Map.put(state, :spaces, List.replace_at(state.spaces, 0, [1, 2, 3, 4, 0]))
    anothernewstate = Map.put(state, :spaces, List.replace_at(state.spaces, 0, [1, 2, 4, 4, 0]))
    assert Santorini.build_space_one(anotherstate, [1,3]) == anothernewstate
  end

  test "advance_turn" do
    players = [[[1,1],[1,2]],[[3,3],[5,5]]]
    state = Santorini.initial_state(players)
    state_json = Poison.encode(state) |> elem(1)
    IO.puts state_json
    new_json = Santorini.advance_turn(state_json, 0)
    IO.puts new_json
  end

  test "random_move_build" do
    players = [[[1,1],[1,2]],[[3,1],[5,5]]]
    # testing index 0 or [1,1], [1,2]
    # [1,1] can move to either 2,1 or 2,2, NOT 1,2 since token occupies
    # if moved to [2,1] can then build on 1,1, 2,2, 3,2 since it is only 1 high
    # if moved to [2,2] can then build on 1,1, 2,2, 3,2, NOT 3,3 since it is 4 high
    state = Santorini.initial_state(players)
    # new_players = [[[1,1],[1,3]],[[3,3],[5,5]]]
    # IO.puts "OLD:"
    # IO.inspect state
    Santorini.random_move_build(state, 0)
    # IO.puts "NEW:"
    # IO.inspect new_state
  end
end

{"players":[[[2,3],[4,4]],[[2,5],[3,5]]], "spaces":[[0,0,0,0,2],[1,1,2,0,0],[1,0,0,3,0],[0,0,3,0,0],[0,0,0,1,4]], "turn":18}
