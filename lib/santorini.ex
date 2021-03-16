defmodule Santorini do

  # Rows are arrays, columns are indices within arrays
  def empty_board() do
    r = [0, 0, 0, 0, 0]
    [r,r,r,r,r]
  end

  def initial_state(players) do
    %{ turn: 0, spaces: empty_board(), players: players}
  end

  def all_tokens(s) do
    Map.get(Enum.at(s[:players], 0), :tokens) ++ Map.get(Enum.at(s[:players], 1), :tokens)
  end

  # returns all spaces adjacent to the indicated space
  def adjacent_spaces(space) do
    [r, c|_] = space
    spaces = [[r-1,c-1], [r-1,c], [r-1,c+1],
              [r,c-1], [r,c+1],
              [r+1,c-1], [r+1,c], [r+1,c+1]]

    Enum.filter(spaces, fn([cr, cc|_]) -> cr <= 5 && cr >= 1 && cc <= 5 && cc >= 1 end)
    # this was another way to do it
    # for [cr, cc|_] <- spaces, cr <= 5 && cr >= 1 && cc <= 5 && cc >= 1, into: [], do: [cr, cc]
  end


  # returns true if token is allowed to move into specified space
  # s for state. does not check if token is one space away
  def can_move?(s, token, space) do
    increase_is_max_one = (space_height(s, space) - space_height(s, token)) <= 1
    is_token_free_and_is_not_complete_tower = can_build?(s, space)
    increase_is_max_one && is_token_free_and_is_not_complete_tower
  end

  # only for minotaur opponent token force move where height doesn't matter
  def can_move_min?(s, token, space) do
    can_build?(s, space)
  end

  # returns true if apollo can move to a token
  def can_move_apollo?(s, token, space) do
    increase_is_max_one = (space_height(s, space) - space_height(s, token)) <= 1
    is_not_complete_tower = space_height(s, space) < 4
    opponents = Map.get(Enum.at(s[:players], 1), :tokens)
    is_space_free = Enum.reduce_while(opponents, true, fn token, acc ->
      if acc do
        {:cont, space != token }
      else
        {:halt, false}
      end
    end)
    !is_space_free && increase_is_max_one && is_not_complete_tower
  end

  def can_build?(s, space) do
    # elixir question: is there a better way to test
    is_token_free = Enum.reduce_while(all_tokens(s), true, fn token, acc ->
      if acc do
        {:cont, space != token }
      else
        {:halt, false}
      end
    end)
    is_not_complete_tower = space_height(s, space) < 4
    # IO.inspect is_token_free
    # IO.inspect increase_is_max_one
    # IO.inspect is_not_complete_tower
    is_token_free && is_not_complete_tower
  end

  def can_build_same_height?(s, space, token_building) do
    # elixir question: is there a better way to test
    is_token_free = Enum.reduce_while(all_tokens(s), true, fn token, acc ->
      if acc do
        {:cont, space != token }
      else
        {:halt, false}
      end
    end)
    is_not_complete_tower = space_height(s, space) < 4
    is_lowersame_than_token = space_height(s, space) <= space_height(s, token_building)
    is_token_free && is_not_complete_tower && is_lowersame_than_token
  end

  # returns an array of all valid spaces a token can move into
  def valid_spaces_to_move_into(s, token) do
    adjacents = adjacent_spaces(token)
    Enum.filter(adjacents, &(can_move?(s, token, &1)))
  end

  # returns an array of all valid spaces that can be built on by a moved token
  def valid_spaces_to_build_on(s, token) do
    adjacents = adjacent_spaces(token)
    Enum.filter(adjacents, &(can_build?(s, &1)))
  end

  def update_player(s, old_coords, new_coords) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    # remove old ones and add new
    updated = for token <- tokens, do: if token == old_coords, do: new_coords, else: token
    new_player = Map.put(Enum.at(s[:players], 0), :tokens, updated)
    # reverse so opposing player tokens are now in the 0th index
    # Map.put(s, :players, Enum.reverse(new_player))
    Map.put(s, :players, [Enum.at(s[:players], 1), new_player])
  end

  # used by minotaur to change an opponent's spot. called after moving first so don't reverse
  def update_opponent(s, old_coords, new_coords) do
    # already reversed so index 0
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    # remove old ones and add new
    updated = for token <- tokens, do: if token == old_coords, do: new_coords, else: token
    new_player = Map.put(Enum.at(s[:players], 0), :tokens, updated)
    # reverse so opposing player tokens are now in the 0th index
    # Map.put(s, :players, Enum.reverse(new_player))
    Map.put(s, :players, [new_player, Enum.at(s[:players], 1)])
  end

  # changes the position of two players for apollo
  def switch_players(s, old_coords, new_coords) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    # remove old ones and add new
    updated = for token <- tokens, do: if token == old_coords, do: new_coords, else: token
    new_player = Map.put(Enum.at(s[:players], 0), :tokens, updated)

    otokens = Map.get(Enum.at(s[:players], 1), :tokens)
    # remove old ones and add new
    oupdated = for token <- otokens, do: if token == new_coords, do: old_coords, else: token
    onew_player = Map.put(Enum.at(s[:players], 1), :tokens, oupdated)
    # reverse so opposing player tokens are now in the 0th index
    Map.put(s, :players, [onew_player, new_player])
  end

  def build_space_one(s, space) do
    row = Enum.at(s[:spaces], Enum.at(space, 0) - 1)
    old_height = space_height(s, space)
    new_row = List.replace_at(row, Enum.at(space, 1) - 1, old_height + 1)
    new_spaces = List.replace_at(s[:spaces], Enum.at(space, 0) - 1, new_row)
    Map.put(s, :spaces, new_spaces)
  end

  # used by atlas to max out a space
  def build_space_to_4(s, space) do
    row = Enum.at(s[:spaces], Enum.at(space, 0) - 1)
    old_height = space_height(s, space)
    new_row = List.replace_at(row, Enum.at(space, 1) - 1, 4)
    new_spaces = List.replace_at(s[:spaces], Enum.at(space, 0) - 1, new_row)
    Map.put(s, :spaces, new_spaces)
  end

  # generates all possible valid move states for one player, then picks one
  def default_move_build_states(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          Enum.map(builds, fn space_to_build ->
            build_space_one(moved_state, space_to_build)
          end)
        end
      end
    end
  end

  # example: {"turn":0,"players":[{"tokens":[[2,3],[4,4]],"card":"Apollo"},{"tokens":[[2,5],[3,5]],"card":"Prometheus"}],"spaces":[[0,0,0,0,2],[1,1,2,0,0],[1,0,0,3,0],[0,0,3,0,0],[0,0,0,1,4]]}
  def extra_states_apollo(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      adjacents = adjacent_spaces(token)
      moves = Enum.filter(adjacents, &(can_move_apollo?(s, token, &1)))
      for move <- moves do
        moved_state = switch_players(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          # I think I don't have to check length since if len is 0, map won't do anything?
          # if length(builds) > 0 do
          Enum.map(builds, fn space_to_build ->
            build_space_one(moved_state, space_to_build)
            # should make a list of final states after building
          end)
        end
      end
    end
  end

  def extra_states_artemis(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options AND all extra move+build options
          builds = valid_spaces_to_build_on(moved_state, move)
          states_if_no_extra_move = Enum.map(builds, fn space_to_build ->
            build_space_one(moved_state, space_to_build)
          end)

          # artemis can optionally do an extra move before building with same token if it doesn't go to original spot
          moved_state_ordered = Map.put(s, :players, Enum.reverse(s[:players]))
          moves2 = valid_spaces_to_move_into(moved_state_ordered, move)
          # remove original location token was in so it can't just go back
          moves2_not_original_spot = List.delete(moves2, token)
          states_with_extra_move = for move2 <- moves2_not_original_spot do
            # 'move' is now the location of the token after being moved once
            movedagain_state = update_player(moved_state_ordered, move, move2)
            if space_height(movedagain_state, move) == 3 do
              movedagain_state
            else
            # otherwise generate all build options AND all extra move+build options
              builds2 = valid_spaces_to_build_on(movedagain_state, move2)
              Enum.map(builds2, fn space_to_build ->
                build_space_one(movedagain_state, space_to_build)
              end)
            end
          end
          states_if_no_extra_move
        end
      end
    end
  end

  def extra_states_atlas(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          Enum.map(builds, fn space_to_build ->
            build_space_to_4(moved_state, space_to_build)
          end)
        end
      end
    end
  end

  def extra_states_demeter(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          states_after_build1 = Enum.map(builds, fn space_to_build ->
            build_space_one(moved_state, space_to_build)
          end)
          # final states are actually after building twice
          for bstate <- states_after_build1 do
            builds2 = valid_spaces_to_build_on(bstate, move)
            builds2_no_first_build = List.delete(builds2, bstate)
            Enum.map(builds2_no_first_build, fn space_to_build ->
              build_space_one(moved_state, space_to_build)
            end)
          end
        end
      end
    end
  end

  def extra_states_hephastus(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        # if token moved onto a level 3 space, do not build
        if space_height(moved_state, move) == 3 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          states_after_build1 = Enum.map(builds, fn space_to_build ->
            built_state = build_space_one(moved_state, space_to_build)
            if space_height(built_state, space_to_build) < 3 do
              build_space_one(built_state, space_to_build)
            else
              built_state
            end
          end)
        end
      end
    end
  end

  def extra_states_minotaur(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      # moves = valid_spaces_to_move_into(s, token)
      # only get moves where minotaur forces another token to move
      adjacents = adjacent_spaces(token)
      moves = Enum.filter(adjacents, &(can_move_apollo?(s, token, &1)))
      build = []
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)
        oadjacents = adjacent_spaces(move)
        # what if minotaur token pushes it into its old spot?
        omoves = Enum.filter(oadjacents, &(can_move_min?(s, move, &1)))
        oldmove = move
        for move <- omoves do
          moved_state = update_opponent(moved_state, oldmove, move)

          # if token moved onto a level 3 space, do not build
          if space_height(moved_state, move) == 3 do
            moved_state
          else
          # otherwise generate all build options
            builds = valid_spaces_to_build_on(moved_state, oldmove)
            Enum.map(build, fn space_to_build ->
              build_space_one(moved_state, space_to_build)
            end)
          end
        end
      end
    end
  end
  def extra_states_pan(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      for move <- moves do
        moved_state = update_player(s, token, move)
        # also increment turn here since we may or may not build
        moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

        difference_in_move_height = space_height(moved_state, move) - space_height(s, token)

        # if token went down 2+ levels or moved onto a level 3 space, do not build cause win
        if space_height(moved_state, move) == 3 || difference_in_move_height <= -2 do
          moved_state
        else
        # otherwise generate all build options
          builds = valid_spaces_to_build_on(moved_state, move)
          Enum.map(builds, fn space_to_build ->
            build_space_one(moved_state, space_to_build)
          end)
        end
      end
    end
  end

  def extra_states_prometheus(s) do
    tokens = Map.get(Enum.at(s[:players], 0), :tokens)
    for token <- tokens do
      # prometheus can optionally build before moving
      adjacents = adjacent_spaces(token)
      builds = Enum.filter(adjacents, &(can_build_same_height?(s, &1, token)))
      built_s = Enum.map(builds, fn space_to_build ->
        build_space_one(s, space_to_build) end)

      for s2 <- built_s do
        moves = valid_spaces_to_move_into(s2, token)
        for move <- moves do
          moved_state = update_player(s, token, move)
          # also increment turn here since we may or may not build
          moved_state = Map.put(moved_state, :turn, moved_state[:turn] + 1)

          # if token moved onto a level 3 space, do not build
          if space_height(moved_state, move) == 3 do
            moved_state
          else
          # otherwise generate all build options
            builds = valid_spaces_to_build_on(moved_state, move)
            Enum.map(builds, fn space_to_build ->
              build_space_one(moved_state, space_to_build)
            end)
          end
        end
      end
    end
  end

  def get_extra_card_states(s, card) do
    case card do
      "Apollo" -> extra_states_apollo(s)
      "Artemis" -> extra_states_artemis(s)
      "Atlas" -> extra_states_atlas(s)
      "Demeter" -> extra_states_demeter(s)
      "Hephastus" -> extra_states_hephastus(s)
      "Minotaur" -> extra_states_minotaur(s)
      "Pan" -> extra_states_pan(s)
      "Prometheus" -> extra_states_prometheus(s)
      _ -> "error invalid card"
    end
  end

  # takes a string of json as input, updates the board to a new random valid state, and returns it
  def advance_turn(state_json) do
    state = Poison.decode!(state_json, keys: :atoms)
    card = Map.get(List.first(state[:players]), :card)
    # apply move to board then check for build possibility
    default_newstates = default_move_build_states(state)
    card_ability_newstates = get_extra_card_states(state, card)
    # IO.puts "CARD ABILITIES"
    # IO.inspect(card_ability_newstates)

    newstate = case card do
      # for pan original states can be invalid because moving down 2 levels isn't treated as a win
      "Pan" -> Enum.random(List.flatten(card_ability_newstates))
      _ -> Enum.random(List.flatten(default_newstates ++ card_ability_newstates))
    end
    Poison.encode!(newstate)
  end


  def pick_starting_tokens(opponent_tokens) do
    tokens = [[Enum.random(1..5),Enum.random(1..5)], [Enum.random(1..5),Enum.random(1..5)]]
    if opponent_tokens != nil and (List.first(tokens) in opponent_tokens or List.last(tokens) in opponent_tokens or List.first(tokens) == List.last(tokens)) do
      pick_starting_tokens(opponent_tokens)
    else
      tokens
    end
  end

  # {"players":[{"card":"Artemis","tokens":[[2,3],[4,4]]},{"card":"Prometheus","tokens":[[2,5],[3,5]]}],"spaces":[[0,0,0,0,2],[1,1,2,0,0],[1,0,0,3,0],[0,0,3,0,0],[0,0,0,1,4]],"turn":18}

  # example input: [{"card":"Prometheus"},{"card":"Artemis","tokens":[[2,3],[4,4]]}]
  def process_start_input(input_json) do
    input = Poison.decode!(input_json)

    tokens_input = for row <- input, do: Map.get(row, "tokens")
    token_response = pick_starting_tokens(List.last(tokens_input))

    changed_and_now_last = Map.put(List.first(input), "tokens", token_response)
    response = [List.last(input), changed_and_now_last]

    Poison.encode!(response)
  end

  # forevor loop taking turns
  def turn_input_output() do
    state_json = IO.gets(:stdio, "")
    # state should always have this cpu player as first
    new_state_json = advance_turn(state_json)
    IO.puts(new_state_json)
    turn_input_output()
  end

  # start with initial player token input, then loop through turns with json from stdin/stdout
  def play_game() do
    initial_players = IO.gets(:stdio, "")
    if initial_players != "\n" do
      added_cpu_player = process_start_input(initial_players)
      IO.puts(added_cpu_player)
    end
    turn_input_output()
  end

  # get the level of the space or "tower", possible values being 0-4
  def space_height(state, space) do
    row = Enum.at(state[:spaces], Enum.at(space, 0) - 1)
    Enum.at(row, Enum.at(space, 1) - 1)
  end


  def start(_type, _args) do
    # IO.puts("awaiting input")
    play_game()
  end

  def main(_args) do
    play_game()
  end

end

# Santorini.play_game()
