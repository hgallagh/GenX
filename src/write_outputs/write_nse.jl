@doc raw"""
	write_nse(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting non-served energy for every model zone, time step and cost-segment.
"""
function write_nse(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfGen = inputs["dfGen"]
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	SEG = inputs["SEG"] # Number of load curtailment segments
	# Non-served energy/demand curtailment by segment in each time step
	dfNse = DataFrame(Segment = repeat(1:SEG, outer = Z), Zone = repeat(1:Z, inner = SEG), AnnualSum = zeros(SEG * Z))
	nse = zeros(SEG * Z, T)
	for z in 1:Z
		if setup["ParameterScale"] == 1
			nse[((z-1)*SEG+1):z*SEG, :] = value.(EP[:vNSE])[:, :, z] * ModelScalingFactor
		else
			nse[((z-1)*SEG+1):z*SEG, :] = value.(EP[:vNSE])[:, :, z]
		end
	end
	dfNse.AnnualSum .= nse * inputs["omega"]
	dfNse = hcat(dfNse, DataFrame(nse, :auto))
	auxNew_Names=[Symbol("Segment");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfNse,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfNse[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
	total[:, 4:T+3] .= sum(nse, dims = 1)
	rename!(total,auxNew_Names)
	dfNse = vcat(dfNse, total)

	CSV.write(joinpath(path, "nse.csv"),  dftranspose(dfNse, false), writeheader=false)
	return dfNse
end
