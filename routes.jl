# TODO [Adrian]
#=

  + we'll need to append .stipple-core class to body element

  + we don't use roboto in this project

  + HEAD
  + <link href="https://fonts.googleapis.com/css?family=Material+Icons" rel="stylesheet" type="text/css">
  + <link href="https://cdn.jsdelivr.net/npm/animate.css@^4.0.0/animate.min.css" rel="stylesheet" type="text/css">
  + <link href="https://cdn.jsdelivr.net/npm/quasar@1.11.2/dist/quasar.min.css" rel="stylesheet" type="text/css">

  +

=#

using Genie.Router
using Genie.Renderer.Html

using Stipple, Stipple.Layout, Stipple.Elements
using StippleQuasar, StippleQuasar.Select, StippleQuasar.Table, StippleQuasar.Range
using StippleApexCharts, StippleApexCharts.Plots

using CSV, DataFrames, Clustering

import Genie.Renderer.Html: select

data = DataFrames.insertcols!(CSV.read("data/iris.csv")[:, 2:end], :Cluster => zeros(Int, 150))

Base.@kwdef mutable struct Model <: ReactiveModel
  iris_data::R{DataTable} = DataTable(data)
  credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)

  plot_options::PlotOptions = PlotOptions(chart_type=:scatter, xaxis_type=:numeric)
  iris_plot_data::R{Vector{PlotSeries}} = PlotSeries[]
  cluster_plot_data::R{Vector{PlotSeries}} = PlotSeries[]

  features::R{Vector{String}} = ["SepalLength", "SepalWidth", "PetalLength", "PetalWidth"]
  xfeature::R{String} = ""
  yfeature::R{String} = ""

  no_of_clusters::R{Int} = 3
  no_of_iterations::R{Int} = 10
  clustering_features::R{Vector{String}} = ["SepalLength", "SepalWidth", "PetalLength", "PetalWidth"]
end

Stipple.register_components(Model, StippleApexCharts.COMPONENTS)

const model = Stipple.init(Model())

function plot_data(cluster_column::Symbol)
  result = Vector{PlotSeries}()
  isempty(model.xfeature[]) || isempty(model.yfeature[]) && return result

  dimensions = Dict()
  for s in Array(data[:, cluster_column]) |> unique!
    dimensions[s] = []

    for r in eachrow(data[data[cluster_column] .== s, :])
      push!(dimensions[s], [r[Symbol(model.xfeature[])], r[Symbol(model.yfeature[])]])
    end

    push!(result, PlotSeries("$s", PlotData(dimensions[s])))
  end

  result
end

function compute_clusters!()
  features = collect(Matrix(data[:, [Symbol(c) for c in model.clustering_features[]]])')
  result = kmeans(features, model.no_of_clusters[]; maxiter=model.no_of_iterations[])
  data[:Cluster] = assignments(result)
  model.iris_data[] = DataTable(data)
  model.cluster_plot_data[] = plot_data(:Cluster)

  nothing
end

onany(model.xfeature, model.yfeature) do (_...)
  model.iris_plot_data[] = plot_data(:Species)
  compute_clusters!()
end

onany(model.no_of_clusters, model.no_of_iterations, model.clustering_features) do (_...)
  compute_clusters!()
end

function ui(model::Model)
  layout([
    page(root(model), class="container", [
      h3("Iris data k-means clustering")
      row([
        cell(size=10, [
          h5("Iris data")
          table(@data(:iris_data); pagination=:credit_data_pagination, dense=true, flat=true, style="height: 350px;")
        ])
        cell(size=2, [
          h5("Clustering")
          row([
            cell([
              h6("Number of clusters")
              slider(@data(:no_of_clusters), 1:1:20; markers=true, label=true)
            ])
            cell([
              h6("Number of iterations")
              slider(@data(:no_of_iterations), 10:10:200; markers=true, label=true)
            ])
            cell([
              h6("Features")
              select(:clustering_features; options=:features, multiple=true)
            ])
          ])
        ])
      ])
      row([
        cell(size=5, [
          h5("Species clusters")
          plot(@data(:iris_plot_data); options=:plot_options)
        ])
        cell(size=5, [
          h5("k-means clusters")
          plot(@data(:cluster_plot_data); options=:plot_options)
        ])
        cell(size=2, [
          h5("Plotting")
          row([
            cell([
              h6("X feature")
              select(:xfeature; options=:features)
            ])
          ])
          row([
            cell([
              h6("Y feature")
              select(:yfeature; options=:features)
            ])
          ])
        ])
      ])
    ])

    style("
    h1,h2,h3,h4,h5,h6 {
      margin-bottom: auto;
      margin-top: auto;
    }
    .container {
      padding: 10px;
    }
    ")
  ],
  title="Iris Data K-Means Clustering"
  )
end

route("/") do
  ui(model) |> html
end

function __init__()
  push!(Stipple.DEPS, () -> script(src="/js/plugins/genie_autoreload/autoreload.js"))
end

up()