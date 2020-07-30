using Revise

using Genie
using Genie.Router
using Genie.Renderer.Html

using Stipple, Stipple.Layout, Stipple.Elements
using StippleUI, StippleUI.Select, StippleUI.Table, StippleUI.Range, StippleUI.Heading, StippleUI.Dashboard
using StippleCharts, StippleCharts.Charts

using CSV, DataFrames, Clustering

import Genie.Renderer.Html: select

data = DataFrames.insertcols!(DataFrame!(CSV.File("data/iris.csv"))[:, 2:end], :Cluster => zeros(Int, 150))

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

Stipple.register_components(Model, StippleCharts.COMPONENTS)

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
  dashboard(
    root(model), class="container", [
      heading("Iris data k-means clustering")

      row([
        cell(class="st-module", [
          h5("Clustering")

          row([
            cell(size=3, [
              h6("Number of clusters")
              slider( 1:1:20,
                      @data(:no_of_clusters);
                      markers=true, label=true)
            ])
            cell()
            cell(size=3, [
              h6("Number of iterations")
              slider( 10:10:200,
                      @data(:no_of_iterations);
                      markers=true, label=true)
            ])
            cell()
            cell(size=4, [
              h6("Features")
              select(:clustering_features;
                      options=:features, multiple=true)
            ])
          ])
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Plotting")
          row([
            cell([
              h6("X feature")
              select(:xfeature; options=:features)
            ])

            cell([
              h6("Y feature")
              select(:yfeature; options=:features)
            ])
          ])
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Species clusters")
          plot(:iris_plot_data; options=:plot_options)
        ])

        cell(class="st-module", [
          h5("k-means clusters")
          plot(:cluster_plot_data; options=:plot_options)
        ])
      ])

      row([
        cell(class="st-module", [
          h5("Iris data")
          table(:iris_data; pagination=:credit_data_pagination,
                                    dense=true, flat=true, style="height: 350px;")
        ])
      ])

      footer(class="st-footer q-pa-md", [
        cell([
          img(class="st-logo", src="/img/st-logo.svg")
          span(" &copy; 2020")
        ])
      ])
    ], title="Iris Data K-Means Clustering"
  )

end

route("/") do
  ui(model) |> html
end

function __init__()
  push!(Stipple.DEPS, () -> script(src="/js/plugins/genie_autoreload/autoreload.js"))
end

up()