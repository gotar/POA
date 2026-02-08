module MonitoringHelper
  def job_status_color(status)
    case status.to_s
    when "pending", "ready", "scheduled", "blocked"
      "bg-yellow-500"
    when "running", "claimed"
      "bg-blue-500"
    when "completed", "finished"
      "bg-green-500"
    when "failed"
      "bg-red-500"
    else
      "bg-gray-500"
    end
  end
end