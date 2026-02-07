module ScheduledJobsHelper
  def status_badge_class(status)
    case status
    when "pending"
      "bg-yellow-900 text-yellow-200"
    when "running"
      "bg-blue-900 text-blue-200"
    when "completed"
      "bg-green-900 text-green-200"
    when "failed"
      "bg-red-900 text-red-200"
    when "paused"
      "bg-gray-900 text-gray-400"
    else
      "bg-gray-900 text-gray-200"
    end
  end
end