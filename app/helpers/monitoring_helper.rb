module MonitoringHelper
  def job_status_color(status)
    case status
    when "pending"
      "bg-yellow-500"
    when "running"
      "bg-blue-500"
    when "completed"
      "bg-green-500"
    when "failed"
      "bg-red-500"
    else
      "bg-gray-500"
    end
  end
end