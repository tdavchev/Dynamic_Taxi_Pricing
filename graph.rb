class Graph

  # Constructor
  
  attr_accessor :d,:nodes,:dist

  def initialize
    @g = {}  # the graph // {node => { edge1 => weight, edge2 => weight}, node2 => ...
    @nodes = Array.new     
    @INFINITY = 1 << 64    
  end


  def add_node(n)
    @nodes << n
  end

  def remove_edge(s,t)
    @g[s].delete(t)
    @g[t].delete(s)
  end

  def edge?(s,t)
    !@g[s][t].nil?
  end
    
  def add_edge(s,t,w)     # s= source, t= target, w= weight
    if (not @g.has_key?(s))  
      @g[s] = {t=>w}     
    else
      @g[s][t] = w         
    end
    
    # Begin code for non directed graph (inserts the other edge too)
    
    if (not @g.has_key?(t))
      @g[t] = {s=>w}
    else
      @g[t][s] = w
    end

    # End code for non directed graph (ie. deleteme if you want it directed)

    if (not @nodes.include?(s)) 
      @nodes << s
    end
    if (not @nodes.include?(t))
      @nodes << t
    end 
  end


  # based of wikipedia's pseudocode:
  # http://en.wikipedia.org/wiki/Dijkstra's_algorithm
  
  def dijkstra(s)
    @d = {}
    @prev = {}

    @nodes.each do |i|
      @d[i] = @INFINITY
      @prev[i] = -1
    end 

    @d[s] = 0
    q = @nodes.compact
    while (q.size > 0)
      u = nil;
      q.each do |min|
        if (not u) or (@d[min] and @d[min] < @d[u])
          u = min
        end
      end
      if (@d[u] == @INFINITY)
        break
      end
      q = q - [u]
      @g[u].keys.each do |v|
        alt = @d[u] + @g[u][v]
        if (alt < @d[v])
          @d[v] = alt
          @prev[v]  = u
        end
      end
    end
  end

  def neighbours(n)
    return  @g[n].keys
  end
  
  # To print the full shortest route to a node
  
  def print_path(dest)
    if @prev[dest] != -1
      print_path @prev[dest]
    end
    print ">#{dest}"
  end

  def path(dest)
    c=@prev[dest]
    if c==-1
      return []
    else
      p=[dest]
      while (c!=-1)
        p<<c
        c=@prev[c]
      end  
      return p.reverse
    end  
  end

  def spanning_forest
    @dist=Hash.new
    @path=Hash.new
    @nodes.each do |source|
      dijkstra source
      @dist[source]=Hash.new
      @path[source]=Hash.new
      @nodes.each do |dest|
        @dist[source][dest]=@d[dest]
        @path[source][dest]=path(dest)
      end  
    end
    return [@dist, @path]
  end
  
  # Gets all shortests paths using dijkstra
  public
  def shortest_paths(s)
    @source = s
    dijkstra s
    puts "Source: #{@source}"
    @nodes.each do |dest|
      puts "\nTarget: #{dest}"
      print_path dest
      if @d[dest] != @INFINITY
        puts "\nDistance: #{@d[dest]}"
      else
        puts "\nNO PATH"
      end
    end
  end
end


def generateGraph(numVert,beta,k)
  nodes=[]
  graph=Graph.new
  r=Random.new

  (1..numVert).each do |i|
    nodes<<"#{i}"
  end

  (0...nodes.length).each do |i|
    (1..k/2).each do |j|
      graph.add_edge(nodes[i],nodes[i-j],r.rand(5..20))
      graph.add_edge(nodes[i],nodes[(i+j)%nodes.length],r.rand(5..20))
    end
  end
  (0...nodes.length).each do |i|
    (0...nodes.length).each do |j|
      if j<i && graph.edge?(nodes[i],nodes[j]) && rand<beta
        begin
          targ=rand(nodes.length)
        end until targ!=i && !graph.edge?(nodes[i],nodes[targ])  
        graph.remove_edge(nodes[i],nodes[j])
        graph.add_edge(nodes[i],nodes[targ],r.rand(5..20))
      end  
    end  
  end 
  return graph
end

#commuting likelihood of a destination should be proportional to distance to node, but weighted by population size - more chance of commuting to a large city than a small city
#Arbitrary formula: (size/dist) is attraction level, normalized over all cities.

def generateNodeTravelLikelihoods(graph)
  destinations=Hash.new
  destinations[nil]=Hash.new
  sf=graph.spanning_forest
  population=Hash.new
  graph.nodes.each do |n|
    population[n]=rand(1000)
  end
  
  graph.nodes.each do |s|
    sumdist=0
    normalised=Hash.new
    propCom=rand #the prportion who commute (0..1)
    graph.nodes.each do |t|
     if (s.eql?(t))
       next
     end  
     #puts "distance from #{s} to #{t} is #{sf[0][s][t]}"
     sumdist+=sf[0][s][t] 
     normalised[t]=population[t]/sf[0][s][t]*propCom
    end

    graph.nodes.each do |t|
      normalised[t]||=0
      normalised[t]/=sumdist
    end
    destinations[s]=normalised
#fix outlier cases
    destinations[s][s]=0
    sum=0; destinations[s].each_value {|i| sum+=i}
    destinations[s][nil]=1-sum
    destinations[nil][s]=0
  end  
  return destinations
end



if __FILE__ == $0
  gr = Graph.new
  gr.add_edge("a","b",5)
  gr.add_edge("b","c",3)
  gr.add_edge("c","d",1)
  gr.add_edge("a","d",10)
  gr.add_edge("b","d",2)
  gr.add_edge("f","g",1)
  gr.shortest_paths("a")
  destinations = generateNodeTravelLikelihoods(gr)
end

