#=
Optimisation du modèle

/!\ Uniquement pour les centrales thermiques pour le moment
=#

using JuMP, CPLEX

model = read_from_file("model_problem_debug.mps")
set_optimizer(model, CPLEX.Optimizer)

#set_optimizer_attribute(model, "CPLEX.log_level", 1)
set_optimizer_attribute(model, "CPX_PARAM_FEASOPTMODE", 1)
set_optimizer_attribute(model, "CPX_PARAM_TILIM", 60)  
set_optimizer_attribute(model, "CPX_PARAM_CONFLICTDISPLAY", 2) 
set_optimizer_attribute(model, "CPX_PARAM_WRITELEVEL", 2)  
set_optimizer_attribute(model, "CPX_PARAM_WORKDIR", "./logs")
set_optimizer_attribute(model, "CPX_PARAM_MIPDISPLAY", 4) 


#show(model)

optimize!(model)

display(solution_summary(model))
#println(objective_value(model))

#MOI.submit(model, MOI.ConflictRefiner())

#compute_conflict!(model)
#println(MOI.ConflictStatusCode(model))

#=
P = value(P)
U = value(U)
S = value(S)

final_cost = objective_value(model)

println("Cout final : ",final_cost)
println("Puissance centrale 1 (t de 1 à 5)", P[1,1:5])
=#