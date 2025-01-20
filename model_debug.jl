using Serialization


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


println("Puissance à t=-1 : ",sum(InitPower))
println("Somme Pmin:", sum(Pmin)) 
println("Somme Pmax:", sum(Pmax)) 

Pmax_t0 = []
for i in 1:nbUnit
    if InitialUpDownTime[i] > 0
        push!(Pmax_t0, InitPower[i] + DeltaRampUp[i])
    else
        push!(Pmax_t0, Pmin[i])
    end
end

println("Puissance max à t=0 :", sum(Pmax_t0))
println("Demande à t=0 : ",Demand[1])
println("Somme des RampUp : ", sum(DeltaRampUp))
println("Somme des RampDown : ", sum(DeltaRampDown))

println(Demand)