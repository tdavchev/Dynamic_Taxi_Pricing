#bids the optimal value only, has to bid if a bid is possible, stays where they are if no one is around
require 'finite_mdp'
require './taxiSystem.rb'

class OptimalNonMovingModel
 include FiniteMDP::Model

MAXBID=80


def initialize(graph)
  @g=graph
end

def states
  posStates=[]
  @g.nodes.each do |i|
    posStates<<[:normal,i,nil]
    @g.nodes.each do |j|
      if @g.p[i][j]>0
        posStates<<[:normal,i,j]
        posStates<<[:reward,i,j,@g.optbid(i,j)]
      end  
    end
  end  
  return posStates

end
#the possible actions are move and bid. For a normal state, the move
#actions are indexed by where one wants to move to. For a bid action, the
#indexes are the amount bid, the destination, and where one wants to move to if the bid fails.
#There is also a null action from a reward state to the destination state
def actions(state)
  if state[0]==:reward
    return [[:virtualAction]]
  end  

  actions=[]
#we can also stay where we are
  if (state[2]!=nil)
    actions<<[:bid,state[1],state[2],@g.optbid(state[1],state[2])]
  else    
    actions<<[:move,state[1]]
  end  
  return actions
end

def next_states(state,action)
  nextStates=[]
  if action[0]==:virtualAction
    i=state[2]
    @g.nodes.each do |j|
      if (@g.p[i][j]>0)
        nextStates<<[:normal,i,j]
      end  
    end
    nextStates<<[:normal,i,nil]
    return nextStates
  elsif action[0]==:bid #the next state of a successful bid action
    nextStates<<[:reward,state[1],state[2],action[3]]
  end  
  #what is left is a move or a bid action and we must handle the neighbour case
  i=action[1]
  @g.nodes.each do |j|
    if (@g.p[i][j]>0)
      nextStates<<[:normal,i,j]
    end  
  end
  nextStates<<[:normal,i,nil]
  return nextStates
end

def transition_probability(state,action,next_state)


# Start Cheng's modification
# old
##probability of ending up in a reward state
#if (next_state[0]==:reward)
#  return @g.df(action[3],state[1],state[2])
#end
#otherwise the probability is the probability of the next state appearing
#  return @g.p[next_state[1]][next_state[2]]
# revised
    if action[0] ==:virtualAction
      if state[0] ==:reward && next_state[0] ==:normal
        #puts "s.#{state[1]}.#{state[2]}.#{state[3]} to s.#{next_state[1]}.#{next_state[2]} "
        #puts  @g.p[next_state[1]][next_state[2]]
        return @g.p[next_state[1]][next_state[2]]
      else
        return 0
      end
    elsif action[0] ==:bid
      if state[0]==:normal && next_state[0] ==:reward
        return @g.df(action[3]/5, state[1], state[2])
      elsif state[0] ==:normal && next_state[0] ==:normal
        return (1-@g.df(action[3]/5, state[1], state[2])) * @g.p[next_state[1]][next_state[2]]
      end
    elsif action[0] ==:move
      return @g.p[action[1]][next_state[2]]
    else
      return 0
    end
# End Cheng's modification

end

def reward(state,action,next_state)

  # Start Cheng's modification
  # old
  #if action[0]==:virtualAction
  #  return 0
  #end
  #if next_state[0]==:reward
  #  return next_state[3]-@g.c(next_state[1],next_state[2])
  #else
  #  return -@g.c(state[1],next_state[1])
  #end
  #revised
  if action[0] ==:virtualAction
    return 0
  end

  if next_state[0] ==:reward && action[0] ==:bid
    return next_state[3] - @g.c(next_state[1], next_state[2])
  else
    return -@g.c(state[1], action[1])
  end
  # End Cheng's modification

end


# to print the policy after the MDP solver find it
def printPolicy  policy



  output = File.new("po4.txt", "w")

  policy.each do |key, array|
    puts
    if key[0]==:normal
      if key[2].nil?
        puts "[:#{key[0]}, #{key[1]}, nil]"
        output << "[:#{key[0]}, #{key[1]}, nil] \n"
      else
        puts "[:#{key[0]}, #{key[1]}, #{key[2]}]"
        output << "[:#{key[0]}, #{key[1]}, #{key[2]}] \n"
      end
    else
      puts "[:#{key[0]}, #{key[1]}, #{key[2]}, #{key[3]}]"
      output <<  "[:#{key[0]}, #{key[1]}, #{key[2]}, #{key[3]}] \n"
    end

    if array[0]==:move
      puts "--- [:#{array[0]}, #{array[1]}]"
      output <<  "--- [:#{array[0]}, #{array[1]}] \n"
    elsif   array[0]==:bid
      puts "--- [:#{array[0]}, #{array[1]}, #{array[2]}, #{array[3]}]"
      output <<  "--- [:#{array[0]}, #{array[1]}, #{array[2]}, #{array[3]}] \n"
    elsif array[0]==:virtualAction
      puts "--- [:#{array[0]}]"
      output << "--- [:#{array[0]}] \n"
    end
    output << "\n"
  end

  output.close

end


end
