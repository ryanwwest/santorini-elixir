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
    Enum.at(s[:players], 0) ++ Enum.at(s[:players], 1)
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

  # does not preserve token order (which currently doesn't matter)
  def update_token(s, player_index, old_coords, new_coords) do
    player = Enum.at(s[:players], player_index)
    # remove old ones and add new
    updated = for token <- player, do: if token == old_coords, do: new_coords, else: token
    new_player = List.replace_at(s[:players], player_index, updated)
    # reverse so opposing player tokens are now in the 0th index
    Map.put(s, :players, Enum.reverse(new_player))
  end

  def build_space_one(s, space) do
    row = Enum.at(s[:spaces], Enum.at(space, 0) - 1)
    old_height = space_height(s, space)
    new_row = List.replace_at(row, Enum.at(space, 1) - 1, old_height + 1)
    new_spaces = List.replace_at(s[:spaces], Enum.at(space, 0) - 1, new_row)
    Map.put(s, :spaces, new_spaces)
  end

  # generates all possible valid move states for one player, then picks one
  def random_move_build(s, player_index) do
    tokens = (Enum.at(s[:players], player_index))
    possibilities = for token <- tokens do
      moves = valid_spaces_to_move_into(s, token)
      # I think I don't have to check length since if len is 0, map won't do anything?
      # if length(moves) > 0 do
      # this creates a list of lists.. we want it to be one flat list
      for move <- moves do
        moved_state = update_token(s, player_index, token, move)
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

    # todo test if there are 0 possibilities (I assume that would be nil here but who knows)
    Enum.random(List.flatten(possibilities))
  end

  # takes a string of json as input, updates the board to a new random valid state, and returns it
  def advance_turn(state_json, player_index) do
    state = Poison.decode!(state_json, keys: :atoms)
    # apply move to board then check for build possibility
    newstate = random_move_build(state, player_index)
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

  def token_json_response(opponent_tokens) do
    tokens = pick_starting_tokens(opponent_tokens)
    if opponent_tokens != nil do
      [opponent_tokens, tokens]
    else
      [tokens]
    end
  end


  #todo test
  def process_start_input(input_json) do
    input = Poison.decode!(input_json)

    token_response = case length(input) do
      0 -> token_json_response(:nil)
      1 -> token_json_response(List.first(input))
      _ -> :error
    end

    Poison.encode!(token_response)
  end

  # forevor loop taking turns
  def turn_input_output() do
    state_json = IO.gets(:stdio, "")
    # state should always have this cpu player as first
    new_state_json = advance_turn(state_json, 0)
    IO.puts(new_state_json)
    turn_input_output()
  end

  # start with initial player token input, then loop through turns with json from stdin/stdout
  def play_game() do
    initial_players = IO.gets(:stdio, "")
    added_cpu_player = process_start_input(initial_players)
    IO.puts(added_cpu_player)
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
