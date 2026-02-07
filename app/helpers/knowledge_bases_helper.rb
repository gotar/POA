module KnowledgeBasesHelper
  def category_badge_class(category)
    case category
    when "context"
      "bg-blue-900 text-blue-200"
    when "reference"
      "bg-green-900 text-green-200"
    when "code"
      "bg-purple-900 text-purple-200"
    when "example"
      "bg-orange-900 text-orange-200"
    else
      "bg-gray-900 text-gray-200"
    end
  end
end