#=
Construction du model

/!\ Uniquement pour les centrales thermiques pour le moment

Integer infeasible si condition sur le gradient et Min arrêt sont présent en même à t=0
=#

using JuMP, Serialization


#Recupération des données du problèmes
global_data = deserialize("model_data_Global.dat")
data = deserialize("model_data_Th.dat")
#=
Ordre dans serialization data_Th :
nbUnitTh,PminTh,PmaxTh,DeltaRampUpTh,DeltaRampDownTh,InitialUpDownTime,
InitPower,RunningCost,MinUpTime,MinDownTime,StartUpCost
=#
T = global_data[1]
Demand = global_data[3]

nbUnit = data[1]
Pmin = data[2]
Pmax = data[3]
DeltaRampUp = data[4]
DeltaRampDown = data[5]
InitialUpDownTime = data[6]
InitPower = data[7]
RunningCost = data[8]
MinUpTime = data[9]
MinDownTime =  data[10]
StartUpCost = data[11]



model = Model()

#Création des variables
@variable(model,P[1:nbUnit,1:T] >= 0)   #Puissance produite par centrale i au temps t
@variable(model,U[1:nbUnit,1:T],Bin)    #Centrale i allumé (1) ou non (0) au temps t
@variable(model,S[1:nbUnit,1:T],Bin)    #Allumage de la centrale i au temps t (1)

#Définitions des contraintes


for i in 1:nbUnit
    println(i)

    #Contrainte sur la puissance
    @constraint(model, Pmin[i]*U[i,:] .<= P[i,:])
    @constraint(model, P[i,:] .<= Pmax[i]*U[i,:])

    #Contrainte sur le gradient de puissance au temps initial
    IUDT = InitialUpDownTime[i]
    
        #=RampUp
    if IUDT > 0
        @constraint(model, (P[i,1] - InitPower[i]*U[i,1]) <= U[i,1]*DeltaRampUp[i])
    else 
        @constraint(model, P[i,1] <= U[i,1]*Pmin[i])
    end

        #RampDown
    if IUDT > 0
        @constraint(model, (InitPower[i]- P[i,1])*U[i,1] <= U[i,1]*DeltaRampDown[i])
    else 
        @constraint(model, U[i,1]*P[i,1] <= Pmin[i])
    end =#

    #Contrainte sur S au temps initial
    @constraint(model, S[i,1] >= -U[i,1]*InitialUpDownTime[i]/abs(InitialUpDownTime[i]))

    #Temps min d'allumage et d'arrêt au temps initial 
    tau_plus = MinUpTime[i]
    tau_minus = MinDownTime[i]

    #=
    if IUDT > 0 && tau_plus != IUDT
        @constraint(model, U[i,1] >= (tau_plus - IUDT)/abs(tau_plus - IUDT))
    elseif IUDT <= 0 && tau_minus != -IUDT
        @constraint(model, U[i,1] <= (1-((tau_minus + IUDT)/abs(tau_minus + IUDT))))
    elseif IUDT > 0 && tau_plus == IUDT
        @constraint(model, U[i,1] >= 0)
    elseif IUDT <= 0 && tau_minus == -IUDT
        @constraint(model, U[i,1] <= 1)
    end=#

    # Uniquement contrainte de min d'allumage au temps initial 
    if IUDT > 0 && tau_plus != IUDT
        @constraint(model, U[i,1] >= (tau_plus - IUDT)/abs(tau_plus - IUDT))
    elseif IUDT > 0 && tau_plus == IUDT
        @constraint(model, U[i,1] >= 0)
    end 


    #Uniquement contrainte de min d'arret au temps initial
    if IUDT <= 0 && tau_minus != -IUDT
        @constraint(model, U[i,1] <= (1-((tau_minus + IUDT)/abs(tau_minus + IUDT))))
    elseif IUDT <= 0 && tau_minus == -IUDT
        @constraint(model, U[i,1] <= 1)
    end

    for t in 2:T
        #Gradient de puissance pour tout t > 1
        @constraint(model,(P[i,t-1]-P[i,t]) <= (DeltaRampDown[i]*(1+U[i,t]-U[i,t-1]) - 0.5*Pmax[i]*(U[i,t]-U[i,t-1]))*(1-U[i,t]+U[i,t-1]))
        @constraint(model,(P[i,t]-P[i,t-1]) <= (DeltaRampUp[i]*(1-U[i,t]+U[i,t-1]) + 0.5*Pmin[i]*(U[i,t]-U[i,t-1]))*(1+U[i,t]-U[i,t-1]))

        #S pour tout t>1
        @constraint(model, S[i,t] >= (U[i,t]-U[i,t-1]))

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
@objective(model,Min,sum(P.*RunningCost + S.*StartUpCost))


println("Model complete : Writting to file")
write_to_file(model, "model_problem.mps")