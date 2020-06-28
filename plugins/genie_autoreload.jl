using Genie, Genie.Router, Genie.WebChannels, Genie.Util, Genie.Configuration
using Revise
using Distributed, Logging

Genie.config.websockets_server = true

const WEBCHANNEL_NAME = "autoreload"
const GENIE_AUTORELOAD = true
const WATCHED_FOLDERS = ["public", pwd()]

function collect_watched_files(folders::Vector{String} = String[])
  result = String[]

  for f in folders
    try
      push!(result, Genie.Util.walk_dir(f, only_extensions = ["jl", "html", "md", "js", "css"])...)
    catch ex
      @error ex
    end
  end

  result
end

function watch()
  @info "Watching $WATCHED_FOLDERS"

  entr(collect_watched_files(WATCHED_FOLDERS)) do
    @info "Reloading!"

    try
      Genie.WebChannels.message(WEBCHANNEL_NAME, "autoreload:full")
    catch ex
      # @error ex
    end
  end
end

if Genie.Configuration.isdev()
  channel("/$WEBCHANNEL_NAME/subscribe") do
    WebChannels.subscribe(@params(:WS_CLIENT), WEBCHANNEL_NAME)
    @show "Subscription OK"
  end

  @spawn watch()
  @spawn WebChannels.unsubscribe_disconnected_clients(WEBCHANNEL_NAME)
end