require 'finite_mdp'

alpha    = 0.1 # Pr(stay at high charge if searching | now have high charge)
beta     = 0.1 # Pr(stay at low charge if searching | now have low charge)
r_search = 2   # reward for searching
r_wait   = 1   # reward for waiting
r_rescue = -3  # reward (actually penalty) for running out of charge

model = FiniteMDP::TableModel.new [
                                      [:high, :search,   :high, alpha,   r_search],
                                      [:high, :search,   :low,  1-alpha, r_search],
                                      [:low,  :search,   :high, 1-beta,  r_rescue],
                                      [:low,  :search,   :low,  beta,    r_search],
                                      [:high, :wait,     :high, 1,       r_wait],
                                      [:high, :wait,     :low,  0,       r_wait],
                                      [:low,  :wait,     :high, 0,       r_wait],
                                      [:low,  :wait,     :low,  1,       r_wait],
                                      [:low,  :recharge, :high, 1,       0],
                                      [:low,  :recharge, :low,  0,       0]]

solver = FiniteMDP::Solver.new(model, 0.95) # discount factor 0.95
solver.policy_iteration 1e-4
policy = solver.policy #=> {:high=>:search, :low=>:recharge}

puts "end of experiment"