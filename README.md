# Iris flowers dataset k-means clustering dashboard

Demo data dashboard built with
[Stipple.jl](https://github.com/GenieFramework/Stipple.jl),
[StippleUI.jl](https://github.com/GenieFramework/StippleUI.jl),
[StippleCharts.jl](https://github.com/GenieFramework/StippleCharts.jl), and
[Genie.jl](https://github.com/GenieFramework/Genie.jl)

## Installation

Clone/download repo.

Open a Julia REPL and `cd` to the app's dir.

```julia
julia> cd(...the app folder...)
```

Install dependencies

```julia
pkg> activate .

pkg> instantiate
```

Load app

```julia
julia> using Genie

julia> Genie.loadapp()
```

The application will start on port 8100. Open your web browser and navigate to <http://localhost:8100>.

Pick the x and y features to render the plots. Use the various slides to control the model.

<img src="https://www.dropbox.com/s/hkyahy8gmv4lae9/Screenshot_Iris_Data_K-Means_Clustering.png?dl=1" width=800>