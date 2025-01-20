#=
Construction du model : tentative de debug

/!\ Uniquement pour les centrales thermiques pour le moment

Sans S : Integer Infeasible
Sans S + sans RampUp et sans RampDown : Solution ok 

=#

using JuMP, Serialization


#Recupération des données du problèmes
data = deserialize("model_data.dat")
#=
Ordre dans serialization :
T,nbUnit,Demand,Pmin,Pmax,DeltaRampUp,DeltaRampDown,InitialUpDownTime,InitPower,Cost,MinUpTime,MinDownTime,StartUpCost
=#
T = data[1]
nbUnit = data[2]
Demand = data[3]
Pmin = data[4]
Pmax = data[5]
DeltaRampUp = data[6]
DeltaRampDown = data[7]
InitialUpDownTime = data[8]
InitPower = data[9]
RunningCost = data[10]
MinUpTime = data[11]
MinDownTime =  data[12]
StartUpCost = data[13]



model = Model()

#Création des variables
@variable(model,P[1:nbUnit,1:T] >= 0)   #Puissance produite par centrale i au temps t
@variable(model,U[1:nbUnit,1:T],Bin)    #Centrale i allumé (1) ou non (0) au temps t


#Définitions des contraintes


for i in 1:nbUnit
    println(i)
    #Contrainte sur la puissance
    @constraint(model, Pmin[i]*U[i,:] .<= P[i,:])
    @constraint(model, P[i,:] .<= Pmax[i]*U[i,:])

    #Contrainte sur le gradient de puissance au temps initial
    @constraint(model, (P[i,1] - InitPower[i]) <= DeltaRampUp[i])
    @constraint(model, (InitPower[i]- P[i,1]) <= DeltaRampDown[i])


    #Temps min d'allumage et d'arrêt au temps initial 
    IUDT = InitialUpDownTime[i]
    tau_plus = MinUpTime[i]
    tau_minus = MinDownTime[i]


    if IUDT > 0 && tau_plus != IUDT
        @constraint(model, U[i,1] >= (tau_plus - IUDT)/abs(tau_plus - IUDT))
    elseif IUDT <= 0 && tau_minus != -IUDT
        @constraint(model, U[i,1] <= (1-((tau_minus + IUDT)/abs(tau_minus + IUDT))))
    elseif IUDT > 0 && tau_plus == IUDT
        @constraint(model, U[i,1] >= 0)
    elseif IUDT <= 0 && tau_minus == -IUDT
        @constraint(model, U[i,1] <= 1)
    end

    for t in 2:T
        #Gradient de puissance pour tout t > 1
        @constraint(model,(P[i,t-1]-P[i,t]) <= (DeltaRampDown[i]*(1+U[i,t]-U[i,t-1]) - 0.5*Pmax[i]*(U[i,t]-U[i,t-1]))*(1-U[i,t]+U[i,t-1]))
        @constraint(model,(P[i,t]-P[i,t-1]) <= (DeltaRampUp[i]*(1-U[i,t]+U[i,t-1]) + 0.5*Pmin[i]*(U[i,t]-U[i,t-1]))*(1+U[i,t]-U[i,t-1]))


        #Temps min d'allumage et d'arrêt
        if t <= tau_plus
            if IUDT > 0
                @constraint(model, sum(U[i,1:t-1])+IUDT >= tau_plus*(U[i,t-1]-U[i,t]))
            else
                @constraint(model,sum(U[i,1:t-1]) >= tau_plus*(U[i,t-1]-U[i,t]))
            end
        else
            @constraint(model, sum(U[i,1+t-tau_plus:t-1]) >= tau_plus*(U[i,t-1]-U[i,t]))
        end

        if t <= tau_minus
            if IUDT > 0
                @constraint(model,sum(1 .- U[i,1:t-1]) >= tau_minus*(U[i,t]-U[i,t-1]))
            else
                @constraint(model,sum(1 .- U[i,1:t-1]) - IUDT >= tau_minus*(U[i,t]-U[i,t-1]))
            end
        else
            @constraint(model, sum(1 .- U[i,1+t-tau_minus:t-1]) >= tau_minus*(U[i,t]-U[i,t-1]))
        end
    end 
  
end

#Contrainte de demande
for t in 1:T
    @constraint(model, sum(P[:,t])>=Demand[t])
end

#Fonction coût
@objective(model,Min,sum(P.*RunningCost))



println("Model complete : Writting to file")
write_to_file(model, "model_problem_debug.mps")