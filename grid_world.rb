require 'finite_mdp'

class AIMAGridModel
  include FiniteMDP::Model

  #
  # @param [Array<Array<Float, nil>>] grid rewards at each point, or nil if a
  #        grid square is an obstacle
  #
  # @param [Array<[i, j]>] terminii coordinates of the terminal states
  #
  def initialize grid, terminii
    @grid, @terminii = grid, terminii
  end

  attr_reader :grid, :terminii

  # every position on the grid is a state, except for obstacles, which are
  # indicated by a nil in the grid
  def states
    is, js = (0...grid.size).to_a, (0...grid.first.size).to_a
    is.product(js).select {|i, j| grid[i][j]} + [:stop]
  end

  # can move north, east, south or west on the grid
  MOVES = {
      '^' => [-1,  0],
      '>' => [ 0,  1],
      'v' => [ 1,  0],
      '<' => [ 0, -1]}

  # agent can move north, south, east or west (unless it's in the :stop
  # state); if it tries to move off the grid or into an obstacle, it stays
  # where it is
  def actions state
    if state == :stop || terminii.member?(state)
      [:stop]
    else
      MOVES.keys
    end
  end

  # define the transition model
  def transition_probability state, action, next_state
    if state == :stop || terminii.member?(state)
      (action == :stop && next_state == :stop) ? 1 : 0
    else
      # agent usually succeeds in moving forward, but sometimes it ends up
      # moving left or right
      move = case action
               when '^' then [['^', 0.8], ['<', 0.1], ['>', 0.1]]
               when '>' then [['>', 0.8], ['^', 0.1], ['v', 0.1]]
               when 'v' then [['v', 0.8], ['<', 0.1], ['>', 0.1]]
               when '<' then [['<', 0.8], ['^', 0.1], ['v', 0.1]]
             end
      move.map {|m, pr|
        m_state = [state[0] + MOVES[m][0], state[1] + MOVES[m][1]]
        m_state = state unless states.member?(m_state) # stay in bounds
        pr if m_state == next_state
      }.compact.inject(:+) || 0
    end
  end

  # reward is given by the grid cells; zero reward for the :stop state
  def reward state, action, next_state
    state == :stop ? 0 : grid[state[0]][state[1]]
  end

  # helper for functions below
  def hash_to_grid hash
    0.upto(grid.size-1).map{|i| 0.upto(grid[i].size-1).map{|j| hash[[i,j]]}}
  end

  # print the values in a grid
  def pretty_value value
    hash_to_grid(Hash[value.map {|s, v| [s, "%+.3f" % v]}]).map{|row|
      row.map{|cell| cell || '      '}.join(' ')}
  end

  # print the policy using ASCII arrows
  def pretty_policy policy
    hash_to_grid(policy).map{|row| row.map{|cell|
      (cell.nil? || cell == :stop) ? ' ' : cell}.join(' ')}
  end
end

# the grid from Figures 17.1, 17.2(a) and 17.3
model = AIMAGridModel.new(
    [[-0.04, -0.04, -0.04,    +1],
     [-0.04,   nil, -0.04,    -1],
     [-0.04, -0.04, -0.04, -0.04]],
    [[0, 3], [1, 3]]) # terminals (the +1 and -1 states)

# sanity check: successor state probabilities must sum to 1
model.check_transition_probabilities_sum



mystates = model.states;

mytransitionprobability = model.transition_probability([0,0], '>', [0,1])


solver = FiniteMDP::Solver.new(model, 1) # discount factor 1
solver.value_iteration(1e-5, 100) #=> true if converged

puts model.pretty_policy(solver.policy)
# output: (matches Figure 17.2(a))
# > > >
# ^   ^
# ^ < < <

puts model.pretty_value(solver.value)
# output: (matches Figure 17.3)
#  0.812  0.868  0.918  1.000
#  0.762         0.660 -1.000
#  0.705  0.655  0.611  0.388

FiniteMDP::TableModel.from_model(model)
table =  FiniteMDP::TableModel.from_model(model)

puts "end"

#=> [[0, 0], "v", [0, 0], 0.1, -0.04]
#   [[0, 0], "v", [0, 1], 0.1, -0.04]
#   [[0, 0], "v", [1, 0], 0.8, -0.04]
#   [[0, 0], "<", [0, 0], 0.9, -0.04]
#   [[0, 0], "<", [1, 0], 0.1, -0.04]
#   [[0, 0], ">", [0, 0], 0.1, -0.04]
#   [[0, 0], ">", [0, 1], 0.8, -0.04]
#   [[0, 0], ">", [1, 0], 0.1, -0.04]
#   ...
#   [:stop, :stop, :stop, 1, 0]