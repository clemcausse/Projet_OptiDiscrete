#=
Collection des données du problèmes 

/!\ Uniquement pour les centrales thermiques pour le moment
=#

using NCDatasets, Serialization

myds = NCDataset("Data/20090907_extended_pHydro_18_none.nc4")
#myds = NCDataset("Data/100_0_1_w.nc4")
#myds = NCDataset("Data/Aurland_1000.nc4")

#Données générales du problèmes
blk0 = myds.group["Block_0"]

T = blk0.dim["TimeHorizon"]
Demand = blk0["ActivePowerDemand"] |> Array

#Tri entre centrales thermiques et hydro
ThUnits = [];
HyUnits = [];
for ky in keys(blk0.group)
    if ( haskey(blk0.group[ky].attrib, "type") )
        if ( blk0.group[ky].attrib["type"] == "ThermalUnitBlock" )
            push!(ThUnits, ky)
        elseif ( blk0.group[ky].attrib["type"] == "HydroUnitBlock" )
            push!(HyUnits, ky)
        end
    end
end

#List of Thermal Units
println("The list of found Thermal units is as follows:")
println( ThUnits )

#Données relatives à chaque centrales thermiques

PminTh = []
PmaxTh = []
DeltaRampUpTh = []
DeltaRampDownTh = []
InitialUpDownTime = []
MinUpTime = []
MinDownTime = []
RunningCost = []
InitPower = []
StartUpCost = []
nbUnitTh = 0

for ky in ThUnits
    println("Handling : ", ky)

    push!(PminTh,blk0.group[ky]["MinPower"][])
    push!(PmaxTh,blk0.group[ky]["MaxPower"][])
    push!(DeltaRampUpTh,blk0.group[ky]["DeltaRampUp"][])
    push!(DeltaRampDownTh,blk0.group[ky]["DeltaRampDown"][])
    IUDT = blk0.group[ky]["InitUpDownTime"][]
    push!(InitialUpDownTime,IUDT)
    push!(MinUpTime,blk0.group[ky]["MinUpTime"][])
    push!(MinDownTime,blk0.group[ky]["MinDownTime"][])
    push!(RunningCost,blk0.group[ky]["LinearTerm"][])
    initP = blk0.group[ky]["InitialPower"][]
    if IUDT <= 0
        initP = 0
    end
    push!(InitPower,initP)
    push!(StartUpCost, blk0.group[ky]["StartUpCost"][])

    global nbUnitTh += 1
end


#List of Hydro Units
println("The list of found Hydro units is as follows:")
println( HyUnits )

#Données relatives à chaque centrales thermiques

NumberReservoirs = []
NumberArcs = []
TotalNumberPieces = []

StartArcs = []
EndArcs = []

Inflows = []
InitialVolumetric = []
MinVolumetric = []
MaxVolumetric = []

InitialFlowRate = []
DeltaRampUpHy = []
DeltaRampDownHy = []
MinFlow = []
MaxFlow = []

PminHy = []
PmaxHy = []
NumberPieces = []
LinearTerm = []
ConstantTerm = []

nbUnitHy = 0

for ky in HyUnits
    println("Handling : ", ky)

    push!(NumberReservoirs,blk0.group[ky].dim["NumberReservoirs"])
    nbArcs = blk0.group[ky].dim["NumberArcs"]
    push!(NumberArcs,nbArcs)
    push!(TotalNumberPieces,blk0.group[ky].dim["TotalNumberPieces"])
    
    push!(StartArcs,blk0.group[ky]["StartArc"] |> Array)
    push!(EndArcs,blk0.group[ky]["EndArc"]|> Array)

    push!(Inflows,blk0.group[ky]["Inflows"]|> Array)
    push!(InitialVolumetric,blk0.group[ky]["InitialVolumetric"]|> Array)
    push!(MinVolumetric,blk0.group[ky]["MinVolumetric"]|> Array)
    push!(MaxVolumetric,blk0.group[ky]["MaxVolumetric"]|> Array)

    push!(InitialFlowRate,blk0.group[ky]["InitialFlowRate"]|> Array)
    push!(DeltaRampUpHy,blk0.group[ky]["DeltaRampUp"]|> Array)
    push!(DeltaRampDownHy,blk0.group[ky]["DeltaRampDown"]|> Array)
    push!(MinFlow,blk0.group[ky]["MinFlow"]|> Array)
    push!(MaxFlow,blk0.group[ky]["MaxFlow"]|> Array)

    push!(PminHy,blk0.group[ky]["MinPower"]|> Array)
    push!(PmaxHy,blk0.group[ky]["MaxPower"]|> Array)
    nbPieces = blk0.group[ky]["NumberPieces"]|> Array
    push!(NumberPieces,nbPieces)

    LT = blk0.group[ky]["LinearTerm"]|> Array
    CT = blk0.group[ky]["ConstantTerm"]|> Array

    LinTerms = []
    ConTerms = []
    push!(LinTerms,LT[1:nbPieces[1]])
    push!(ConTerms,CT[1:nbPieces[1]])

    for i in 2:nbArcs
        s = sum(nbPieces[1:i-1])
        l = nbPieces[i]

        push!(LinTerms,LT[s+1:s+l])
        push!(ConTerms,CT[s+1:s+l])
    end

    push!(LinearTerm,LinTerms)
    push!(ConstantTerm,ConTerms)

    global nbUnitHy +=1
end

nbUnit = nbUnitTh + nbUnitHy

#Sauvegarde des données du problèmes en vu de la construction du problème
serialize("model_data_Global.dat",(T,nbUnit,Demand))

serialize("model_data_Th.dat",(nbUnitTh,PminTh,PmaxTh,DeltaRampUpTh,DeltaRampDownTh,InitialUpDownTime,InitPower,
    RunningCost,MinUpTime,MinDownTime,StartUpCost))

serialize("model_data_Hy.dat",(nbUnitHy,NumberReservoirs,NumberArcs,TotalNumberPieces,StartArcs,EndArcs,Inflows,
    InitialVolumetric,MinVolumetric,MaxVolumetric,InitialFlowRate,DeltaRampUpHy,DeltaRampDownHy,MinFlow,MaxFlow,
    PminHy,PmaxHy,NumberPieces,LinearTerm,ConstantTerm))

close(myds)

