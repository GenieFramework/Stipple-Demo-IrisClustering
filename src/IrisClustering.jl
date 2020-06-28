module IrisClustering

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = IrisClustering))

  include(joinpath("..", "genie.jl"))
end; main()

end
