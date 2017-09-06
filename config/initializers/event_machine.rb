
# Setting up this error handler prevents silent response errors from 
# shutting down EventMachine. Issue crops up when making RidePilot calls
# with a token that wasn't set up for the requesting host.
EM.error_handler do |error|
  Rails.logger.error error
end
