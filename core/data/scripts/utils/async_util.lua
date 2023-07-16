
local M = {}

function M.waitFor(seconds)
    return async.run(function()
        local start = time.getCurrentTime();
        while (time.getCurrentTime() - start):getSeconds() < seconds do
            async.await(async.yield())
        end
        -- The specified time has elapsed, let the promise resolve now
    end, async.OnFrameExecutor)
end

return M
