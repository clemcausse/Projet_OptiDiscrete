#=
Visualisation des resultats

/!\ Uniquement pour les centrales thermiques pour le moment
=#

const output = IOBuffer()

using REPL

const out_terminal = REPL.Terminals.TerminalBuffer(output)

const basic_repl = REPL.BasicREPL(out_terminal)

const basic_display = REPL.REPLDisplay(basic_repl)

Base.pushdisplay(basic_display)

using Plots, Serialization
plotly()
PlotlyKaleido.start()

results = deserialize("result_optimiser.dat")
data = deserialize("model_data.dat")

T = data[1]
nbUnit = data[2]
Demand = data[3]
Pmin = data[4]
Pmax = data[5]

P_values = results[1]
U_values = results[2]
S_values = results[3]


p = areaplot(1:T,transpose(P_values),
xlabel="Pas de temps", ylabel="Puissance",
title="Répartition de la puissance par centrale",label="")

puissance_totale = sum(P_values, dims=1)
plot!(1:T, transpose(puissance_totale), label="Puissance totale", color=:black, lw=2)

plot!(1:T, Demand, label="Demand", color=:darkgreen, lw=2, seriestype=:path,
linestyle=:dot,legend=:bottomright)
display(p)
savefig(p,"repartition_puissance.png")


