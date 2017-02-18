require 'finite_mdp'
require './taxiSystem.rb'

class FullModel
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
        (1..MAXBID).each  {|x| posStates<<[:reward,i,j,x]}
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
  n=@g.neighbours(state[1])
  n.each do |t|
    actions<< [:move,t] #move and where to
    # Begin Cheng

    # please note I use the transition probability to define if the bid is successful or not.
    #
    # old
    #if (state[2]!=nil)
    #  (1..MAXBID).each do |x|
    #    actions<<[:bid,t,state[2],x] #bid, where in case of fail, where in case of success, amount
    #  end
    #end
    #revised
    if (state[2]!=nil)
        (1..MAXBID).each do |x|
         actions<<[:bid,t,state[2],x] #bid, where in case of fail, where in case of success, amount
        end
    end
    # End Cheng
  end

  #we can also stay where we are
  actions<<[:move,state[1]]

   if (state[2]!=nil)
    (1..MAXBID).each do |x|
      actions<<[:bid,state[1],state[2],x]
    end
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
    # Begin Cheng
    #
    # old
    nextStates<<[:reward,state[1],state[2],action[3]]
    #
    # revised
      #nextStates<<[:reward,state[1],state[2],action[3]] # if the bid is successful

      #nextStates<<[:normal, action[1],nil]   # if the bid is failed
      #@g.nodes.each do |j|
      #  if @g.p[action[1]][j]>0
      #    nextStates<<[:normal,action[1],j]
      # end
      #end
   #End Cheng

  # Begin cheng
  # another elsif to handle the move action.
  #elsif action[0]==:move
  #  nextStates<<[:normal,action[1],nil]
  #  @g.nodes.each do |j|
  #    if (@g.p[action[1]][j]>0)
  #      nextStates<<[:normal,action[1],j]
  #    end
  #  end
  # end cheng

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

# Begin Cheng
#
# old
##probability of ending up in a reward state
#if (next_state[0]==:reward)
#  return @g.df(action[3],state[1],state[2])
#end
#otherwise the probability is the probability of the next state appearing
#  return @g.p[next_state[1]][next_state[2]]
#
# revised
  if state[0] ==:reward && action[0] ==:virtualAction
    if next_state[0] ==:normal
      #puts "s.#{state[1]}.#{state[2]}.#{state[3]} to s.#{next_state[1]}.#{next_state[2]} "
      return @g.p[next_state[1]][next_state[2]]
    else
      return 0
    end

  elsif state[0] ==:normal && action[0] ==:bid
    if next_state[0] ==:reward
      return @g.df(action[3]/5, state[1], state[2])
    elsif next_state[0] ==:normal
      return (1-@g.df(action[3]/5, state[1], state[2])) * @g.p[action[1]][next_state[2]]    # next_state[2] could be nil.
    end
  elsif state[0] ==:normal && action[0] ==:move && next_state[0]==:normal
    if state[1] == next_state[1]
      #puts "s.#{state[1]}.#{state[2]} to s.#{next_state[1]}.#{next_state[2]}  #{action[0]}#{action[1]}   #{@g.p[state[1]][next_state[2]]}"
      #puts  @g.p[state[1]][next_state[2]]
         return  @g.p[state[1]][next_state[2]] # stay where we are, the transition probability is @g.p[state[1]][next_state[2]]
    end

     return @g.p[action[1]][next_state[2]]    # move to neighbour, the transition probability is  @g.p[action[1]][next_state[2]]
  else
    return 0 # should never come here
  end
 # End Cheng
end

def reward(state,action,next_state)

  # Begin Cheng
  #
  # old
  #if action[0]==:virtualAction
  #  return 0
  #end

  #if next_state[0]==:reward
  #  return next_state[3]-@g.c(next_state[1],next_state[2])
  #else
  #  return -@g.c(state[1],next_state[1])
  #end
  #
  #revised
  if action[0] ==:virtualAction
     return 0
  end

  if state[0]==:normal && action[0] ==:bid && next_state[0] ==:reward # successful bid
    return action[3] - @g.c(next_state[1], next_state[2])
  elsif    state[0]==:normal &&  action[0] ==:bid &&  next_state[0] ==:normal #failed bid
    return -@g.c(state[1], next_state[1])
  elsif   state[0]==:normal &&    action[0] ==:move   &&  next_state[0] ==:normal  # normal move
    return -@g.c(state[1], next_state[1])
  else
    return -@g.c(state[1], next_state[1])  #should never come here
  end
  # End Cheng
end




  # to print the policy after the MDP solver find it
  def printPolicy  policy

    output = File.new("po1.txt", "w")

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
