class Node
  attr_accessor :routing
  attr_accessor :journeyProb

  def addJourneyProb(destination,probability)
    @journeyProb||=Hash.new
    @journeyProb[destination]=probability
  end

  def addRoute(destination,nextNode)
    @routing||=Hash.new
    @routing[destination]=nextNode
  end

  def tryGenPassenger
    r=rand
    t=0
    @journeyProb.each_key do |k|
      t+=@journeyProb[k]
      if r<t
        return k
      end  
    end 
    return nil
  end
end
