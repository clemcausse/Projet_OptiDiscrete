#=
Collection des données du problèmes 

/!\ Uniquement pour les centrales thermiques pour le moment
=#

using NCDatasets, Serialization

#myds = NCDataset("Data/20090907_extended_pHydro_18_none.nc4")
myds = NCDataset("Data/100_0_2_w.nc4")
#myds = NCDataset("Data/Aurland_1000.nc4")

#Données générales du problèmes
blk0 = myds.group["Block_0"]

nbUnit = blk0.dim["NumberUnits"]
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


#RDonnées relatives à chaque centrales thermiques

Pmin = []
Pmax = []
DeltaRampUp = []
DeltaRampDown = []
InitialUpDownTime = []
MinUpTime = []
MinDownTime = []
RunningCost = []
InitPower = []
StartUpCost = []

for ky in ThUnits
    println("Handling : ", ky)

    push!(Pmin,blk0.group[ky]["MinPower"][])
    push!(Pmax,blk0.group[ky]["MaxPower"][])
    push!(DeltaRampUp,blk0.group[ky]["DeltaRampUp"][])
    push!(DeltaRampDown,blk0.group[ky]["DeltaRampDown"][])
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
end


#Sauvegarde des données du problèmes en vu de la construction du problème
serialize("model_data.dat",(T,nbUnit,Demand,Pmin,Pmax,DeltaRampUp,DeltaRampDown,InitialUpDownTime,InitPower,RunningCost,MinUpTime,MinDownTime,StartUpCost))

close(myds)

