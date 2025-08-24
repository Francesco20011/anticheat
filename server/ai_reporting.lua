--[[
    server/ai_reporting.lua

    Utility functions for reporting aggregated AI detection data. If
    you implement AI analyses you may want to expose summarised
    metrics to administrators via commands or the web dashboard.
    This module collects such helpers. Currently it returns
    placeholder values.
]]

ACAIReport = {}

-- Compute a simple report of the AI analysis results. In a real
-- implementation this might calculate a score for each player or
-- summarise the number of anomalies detected in a time period. Here
-- we return the count of violations recorded so far as a proxy.
function ACAIReport.getReport()
    local violations = ACDB.getViolations()
    local report = {
        totalViolations = #violations,
        lastViolation = violations[#violations]
    }
    return report
end