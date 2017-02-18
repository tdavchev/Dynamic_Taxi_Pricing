require './graph.rb'
require 'pp'
require 'gsl'

class TaxiSystem < Graph
  
  def df(x,source,destination)
#    if x-@dist[source][destination]==0
#      return 1
#    end  
#    b=1.0/(x-@dist[source][destination])
#    return b<0 ? 1 : b
    # GSL::Cdf::gaussian_Q(x, sigma = 1)
    #
    # These methods compute the cumulative distribution
    # functions P(x), Q(x) and their inverses for the Gaussian
    # distribution with standard deviation sigma.
    #
  #puts GSL::Cdf::gaussian_Q(x,@dist[source][destination])
  return GSL::Cdf::gaussian_Q(x,@dist[source][destination])
  end

  #return optimal bid as per first derivative of df
  def optbid(source,destination)
    #return @dist[source][destination]/2
     f=GSL::Function.alloc{|x| x*GSL::Cdf::gaussian_Q(x,@dist[source][destination])}
     g=GSL::Function.alloc{|x| f.eval(x)+x*f.deriv_central(x)[0]}
     s=GSL::Root::FSolver.alloc("bisection")
     s.set(g,1,3*@dist[source][destination])
     (1..20).each {|x| s.iterate}
     if s.root.floor*df(s.root.floor,source,destination)>s.root.ceil*df(s.root.ceil,source,destination)
       return s.root.floor
     else
       return s.root.ceil
     end    
  end

  def c(source,target)
    if (source==target)
      return 0.001 #changed from 1
    else  
      return @dist[source][target]
    end  
  end

#  def dist
#    puts @dist
#    if !@dist.nil?
#      puts "b"
#      return @dist[0]
#    else
#      puts "c"
#      @dist=spanning_forest
#      return @dist[0]
#    end
#  end

  def p
    if !@p.nil?
      return @p
    end

    @p=Hash.new
    @p[nil]=Hash.new
    nodes.each do |s|
      sum=0
      @p[s]=Hash.new
      nodes.each do |t|
        if (s!=t)
          @p[s][t]=rand
          sum=sum+@p[s][t]
        else  
          @p[s][t]=0
        end  
      end
      @p[s][nil]=rand
      sum=sum+@p[s][nil]
      nodes.each {|t| @p[s][t]/=sum}
      @p[s][nil]/=sum
    end  
    return @p

#old code for p below this line

    @p=Hash.new
    @p[nil]=Hash.new
    population=Hash.new
    nodes.each do |n|
      population[n]=rand(10000)
    end

    nodes.each do |s|
      sumdist=0
      normalised=Hash.new
      propCom=rand #the prportion who commute (0..1)
      nodes.each do |t|
       if (s.eql?(t))
         next
       end
       sumdist+=@dist[s][t]
       normalised[t]=(population[t]/@dist[s][t])*propCom
      end

      nodes.each do |t|
        normalised[t]||=0
        normalised[t]/=sumdist
      end
      @p[s]=normalised
#fix outlier cases
      @p[s][s]=0
      sum=0; @p[s].each_value {|i| sum+=i}
      @p[s][nil]=1-sum
      @p[nil][s]=0
    end
    return @p
  end

  # renamed    initialize
  def oldInitialize(numVert,beta,k,minDist,maxDist)
    @g={}
    @nodes=Array.new
    @INFINITY=1<<64

    nodes=[1,2,3]
    add_edge(1,2,10)
    add_edge(1,3,15)

    spanning_forest
    @taxiPos=1
    @util=0
    @p={}
    @p[1]={1=>0,2=>0.6,3=>0.4,nil=>0.0}
    @p[2]={2=>0,3=>0,1=>0.9,nil=>0.1}
    @p[3]={3=>0,2=>0,1=>0.1,nil=>0.9}

    pretty_print_graph @g

    pretty_print_p @p

  end




  # Begin Cheng
  def pretty_print_graph (graph=@g)

    puts "graph"

    output = File.new("graph.txt", "w")


    graph.each do |key, hash|
      puts "#{key} = Hash"
      output <<  "#{key} = Hash \n"
        hash.each do |value1, value2|
          puts "---#{value1} => #{value2}"
          output <<   "---#{value1} => #{value2} \n"
        end
      puts
      output << "\n"
    end

    output.close

  end

  def pretty_print_p (pro=@p)

    puts "p"
    output = File.new("p.txt", "w")
    if pro.nil?
      pro = p
    end

    pro.each do |key, hash|
      puts "#{key} = Hash"
      output << "#{key} = Hash \n"
      hash.each do |value1, value2|
        if value1.nil?
          puts "---nil => #{value2}"
          output <<  "---nil => #{value2} \n"
        else
          puts "---#{value1} => #{value2}"
          output <<  "---#{value1} => #{value2} \n"
        end
      end
       puts
       output << "\n"

    end

    output.close

  end
  #End Cheng

  def taxiPos
    return @taxiPos
  end

#renamed initialise oldInitialise for now
  def  initialize (numVert,beta,k,minDist,maxDist)
    @g={}
    @nodes=Array.new
    @INFINITY=1<<64

    nodes=[]
    r=Random.new

    (1..numVert).each do |i|
      #nodes<<"#{i}"   # Cheng's modification
      nodes<< i  # Cheng's modification
    end

    (0...nodes.length).each do |i|
      (1..k/2).each do |j|
        add_edge(nodes[i],nodes[i-j],r.rand(minDist..maxDist))
        add_edge(nodes[i],nodes[(i+j)%nodes.length],r.rand(minDist..maxDist))
      end
    end
    (0...nodes.length).each do |i|
      (0...nodes.length).each do |j|
        if j<i && edge?(nodes[i],nodes[j]) && rand<beta
          begin
            targ=rand(nodes.length)
          end until targ!=i && !edge?(nodes[i],nodes[targ])
          remove_edge(nodes[i],nodes[j])
          add_edge(nodes[i],nodes[targ],r.rand(minDist..maxDist))
        end  
      end  
    end
    spanning_forest

#initialize the taxi
    @taxiPos=1 #  Cheng's modification    @taxiPos="1"
    @util=0


  end

  def tick(policy)

    r=rand

    s=p[@taxiPos][nil]

    j=0

    state=[:normal,@taxiPos,nil]   # Cheng's modification   state=[:normal,"#{@taxiPos}",nil]
    while s<r
      j+=1
      #print @taxiPos," #{j} f"; puts                  #cheng comment out
      #s+=p[@taxiPos]["#{j}"]
      #state=[:normal,"#{@taxiPos}","#{j}"]
      s+=p[@taxiPos][j]
      state=[:normal,@taxiPos,j]
    end  
    move=policy[state]
    #print "move: "+move.to_s
    #puts "orig pos:"+@taxiPos.to_s
    #puts "orig util:"+@util.to_s

    temp = rand

    if move[0]==:bid && temp<df(move[3]/5,state[1],move[2])    # cheng    old:  df(move[3],move[1],move[2])


      #Begin cheng

      #puts "taxi position: #{@taxiPos}"
      #chanceToSuc = df(move[3]/5,state[1],move[2])
      #puts "#{move[0]} #{move[1]} #{move[2]} #{move[3]} successful #{temp} #{chanceToSuc}"
      #puts
      # End cheng

      @util+=move[3]-c(@taxiPos,move[2])
      @taxiPos=move[2]
    else #handle normal move or failed bid
      #puts rand    <df(move[3],move[1],move[2])    #cheng comment out
      #puts   "#{df(move[3],move[1],move[2])} "     #cheng comment out

      @util-=c(@taxiPos,move[1])
      @taxiPos=move[1]

      #Begin cheng
      #see more details
      #if move[0]==:bid
      #  puts "taxi position: #{@taxiPos}"
      #  chanceToSuc = df(move[3]/5,state[1],move[2])
      #  puts "#{move[0]} #{move[1]} #{move[2]} #{move[3]} failure #{temp} #{chanceToSuc}"
      #  puts
      #elsif  move[0]==:move
      #  puts "taxi position: #{@taxiPos}"
      #  puts "#{move[0]} #{move[1]} "
      #  puts
      #end
      #End cheng

    end

    #puts "new post:"+@taxiPos.to_s
    #puts "newutil:"+@util.to_s
    #puts
    return @util
  end  

  def resetSim
    @taxiPos=1 #  Cheng's modification    @taxiPos="1"
    @util=0
  end


end



if __FILE__ == $0

  t=TaxiSystem.new(15,0.3,4,5,15)



end
