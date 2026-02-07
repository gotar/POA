namespace :qmd do
  desc "Index all knowledge base content with QMD"
  task index: :environment do
    puts "Indexing knowledge base with QMD..."

    begin
      qmd_service = QmdService.new
      qmd_service.index_all
      puts "✅ Knowledge base indexed successfully"
    rescue QmdService::Error => e
      puts "❌ Failed to index knowledge base: #{e.message}"
      exit 1
    end
  end

  desc "Search knowledge base using QMD"
  task :search, [:query] => :environment do |t, args|
    query = args[:query]
    if query.blank?
      puts "Usage: rake qmd:search[query]"
      exit 1
    end

    puts "Searching for: #{query}"

    begin
      qmd_service = QmdService.new
      results = qmd_service.search(query)

      if results.any?
        puts "Found #{results.length} results:"
        results.each do |result|
          puts "- #{result['title']} (score: #{result['score']&.round(3)})"
          puts "  #{result['content']&.truncate(100)}"
          puts
        end
      else
        puts "No results found"
      end
    rescue QmdService::Error => e
      puts "❌ Search failed: #{e.message}"
      exit 1
    end
  end

  desc "Add content to knowledge base"
  task :add, [:title, :content] => :environment do |t, args|
    title = args[:title]
    content = args[:content]

    if title.blank? || content.blank?
      puts "Usage: rake qmd:add[title,content]"
      exit 1
    end

    puts "Adding content: #{title}"

    begin
      qmd_service = QmdService.new
      kb = qmd_service.add_content(title, content)
      puts "✅ Content added successfully (ID: #{kb.id})"
    rescue QmdService::Error => e
      puts "❌ Failed to add content: #{e.message}"
      exit 1
    end
  end
end