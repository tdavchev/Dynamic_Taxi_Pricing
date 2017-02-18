require 'finite_mdp'
require './taxiSystem.rb'
include FiniteMDP

#for a source node i, with possible destinations j1...jn, we have a source
#s_i^j1, s_i^j2... . If we can move to nodes n1,n2,... with n1 having
#destinations q11,q12,... n2 having destinations q21,q22,...
#then we have targets for every s_i^j1, s_i^j2... of
#s_n1^q11, s_n1^q12, ... if we move to n1
#s_n2^q21, s_n2^q22, ... if we move to n2
#note this is from a specific source node to a target node (assumed to be its
#neighbour)
def allPossibleMoves(source,target,graph)
  sources=[]
  targets=[]

  graph.nodes.each do |j|
    if graph.p[source][j]>0
      sources<<j
    end  
    sources<<nil
  end 

  graph.nodes.each do |j|
    if graph.p[target][j]>0
      targets<<j
    end  
    targets<<nil
  end

  apm=[]
  sources.each do |s|
    targets.each do |t|
      #puts "#{source} #{target} a#{s}a b#{t}b"
      #puts "#{graph.p[target][t]}"
      apm<<["s.#{source}.#{target}","move.#{target}","s.#{target}.#{t}",graph.p[target][t],-graph.c(source,target)]
    end
  end
  return apm
end

def allPossibleBidMove(source,destination,target,x,graph)
  v=[]
  moves=[]
  bidSuccess=["s.#{source}.#{destination}",
              "b.#{x}.#{target}",
              "s.#{source}.#{destination}.#{x}",
              graph.df(x,source,destination),
              x-graph.c(source,target)]
  #now generate the reward state to destination state transitions            
  graph.nodes.each do |j|
    v<<["s.#{source}.#{destination}.#{x}",
        "virtualMove",
        "s.#{destination}.#{j}",
        graph.p[destination][j],
        0]
  end
  #now generate the movement
  graph.nodes.each do |k|
    if graph.p[target][k]>0
      moves<<["s.#{source}.#{destination}",
              "b.#{x}.#{target}",
              "s.#{target}.#{k}",
              (1-graph.df(x,source,destination))*graph.p[target][k],
              -graph.c(source,target)]
    end #if           
  end  
  return bidSuccess+v+moves
end


def genMDP(graph)
  m=[]
  graph.nodes.each do |s|
    graph.neighbours(s).each do |t|
      m+=allPossibleMoves(s,t,graph)
      graph.nodes.each do |j|
        if graph.p[s][j]>0
          (1..20).each do |x|
            puts "#{s} #{t} #{j} #{x}"
            m+=allPossibleBidMove(s,j,t,x,graph)
          end
        end  
      end
    end  
  end  
  return m
end



t=TaxiSystem.new(100,0.3,4,5,20)

puts "2"

m=genMDP(t)
puts m.length
