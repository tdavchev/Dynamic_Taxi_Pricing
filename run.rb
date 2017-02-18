 #po.each_key {|k| if k[0]==:normal ; puts "#{k} #{po[k]}"  end } ; nil
 require './model1.rb'
 require './model2.rb'
 require './model3.rb'
 require './model4.rb'
 require 'set'
 t=TaxiSystem.new(15,0.3,4,5,15)


 t.pretty_print_graph

 t.pretty_print_p

 #t=TaxiSystem.new(10,0.3,4,5,10)

 m1=FullModel.new(t)
 #m1.check_transition_probabilities_sum

 m2=OptionalOptimalBidModel.new(t)
 #m2.check_transition_probabilities_sum

 m3=ForcedOptimalBidModel.new(t)
 #m3.check_transition_probabilities_sum

 m4=OptimalNonMovingModel.new(t)
 #m4.check_transition_probabilities_sum

 solver1=FiniteMDP::Solver.new(m1,0.99); nil
 solver2=FiniteMDP::Solver.new(m2,0.99); nil
 solver3=FiniteMDP::Solver.new(m3,0.99); nil
 solver4=FiniteMDP::Solver.new(m4,0.99); nil

 solver1.policy_iteration(0.1)
 solver2.policy_iteration(0.1)
 solver3.value_iteration(0.1)
 solver4.value_iteration(0.1)



 po1=solver1.policy
 m1.printPolicy(po1)      # print the policy

 po2=solver2.policy
 m2.printPolicy(po2)     # print the policy

 po3=solver3.policy
 m3.printPolicy(po3)

 po4=solver4.policy
 m4.printPolicy(po4)


(1..10000).each {t.tick(po1)}
puts t.tick(po1)
t.resetSim

 (1..10000).each {t.tick(po2)}
 puts t.tick(po2)
 t.resetSim

 (1..10000).each {t.tick(po3)}
 puts t.tick(po3)
 t.resetSim

 (1..10000).each {t.tick(po4)}
 puts t.tick(po4)
 t.resetSim

# po=solver.policy
# t.tick(po)
# solver=FiniteMDP::Solver.new(m,0.99); solver.policy_iteration 0.01

# t.p.each_key {|s| t.p[s].each_key {|r| print "#{s},#{r}:";  printf("%.02f",t.p[s][r]); print " "} ; puts "" }; nil
