#=
Optimisation du modèle

/!\ Uniquement pour les centrales thermiques pour le moment
=#

using JuMP, CPLEX, Serialization


model = read_from_file("model_problem.mps")
set_optimizer(model, CPLEX.Optimizer)
#show(model)

optimize!(model)

if is_solved_and_feasible(model)
    data = deserialize("model_data.dat")
    T = data[1]
    nbUnit = data[2]

    P_values = zeros(nbUnit,T)
    U_values = zeros(nbUnit,T)
    S_values = zeros(nbUnit,T)

    println("Collecting Data from the optimiser")
    k = 0
    for var in all_variables(model)
        if k < nbUnit*T
            P_values[k%nbUnit + 1,floor(Int, k/nbUnit)+1] = value(var)
        end

        if k < 2*nbUnit*T && k >= nbUnit*T
            temp_kU = k - nbUnit*T
            U_values[temp_kU%nbUnit + 1,floor(Int, temp_kU/nbUnit)+1] = value(var)
        end

        if k >= 2*nbUnit*T
            temp_kS = k - 2*nbUnit*T
            S_values[temp_kS%nbUnit + 1,floor(Int, temp_kS/nbUnit)+1] = value(var)
        end

        global k += 1
    end
    serialize("result_optimiser.dat",(P_values,U_values,S_values))
    println("Data collected and moved to .dat file")
else
    display(solution_summary(model))
end