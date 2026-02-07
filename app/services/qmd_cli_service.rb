# frozen_string_literal: true

require "open3"
require "json"

class QmdCliService
  class Error < StandardError; end

  DEFAULT_COLLECTION = ENV.fetch("PI_KNOWLEDGE_QMD_COLLECTION", "pi-knowledge")

  def self.qmd_bin
    ENV.fetch("QMD_BIN", "qmd")
  end

  def self.ensure_pi_knowledge_collection!
    PersonalKnowledgeService.ensure_setup!
    ensure_collection!(name: DEFAULT_COLLECTION, path: PersonalKnowledgeService.base_dir, mask: "**/*.md")
  end

  def self.ensure_collection!(name:, path:, mask: "**/*.md")
    list = run!("collection", "list")
    return true if list.include?("\n#{name} ") || list.start_with?("#{name} ") || list.include?("\n#{name}(") || list.include?("\n#{name}\n")

    run!("collection", "add", path.to_s, "--name", name.to_s, "--mask", mask.to_s)
    true
  end

  def self.update!
    ensure_pi_knowledge_collection!
    run!("update")
  end

  def self.update_and_embed_if_needed!
    out = update!
    embed_if_needed!
    out
  end

  def self.embed_if_needed!
    return false if ENV.fetch("QMD_AUTO_EMBED", "true") != "true"

    st = status
    if embed_needed?(st)
      embed!
      return true
    end

    false
  end

  def self.embed_needed?(status_text)
    t = status_text.to_s
    return true if t.match?(/need embedding/i)
    return true if t.match?(/need embeddings/i)
    return true if t.match?(/need vectors/i)
    return true if t.match?(/pending:\s*\d+\s*need/i)

    false
  end

  def self.embed!(force: false)
    ensure_pi_knowledge_collection!
    args = ["embed"]
    args << "-f" if force
    run!(*args)
  end

  def self.status
    run!("status")
  end

  # mode: :query (hybrid), :search (bm25), :vsearch (vector)
  def self.search(query, mode: :query, limit: 10, collection: DEFAULT_COLLECTION)
    ensure_pi_knowledge_collection!

    cmd = case mode.to_sym
          when :search then "search"
          when :vsearch then "vsearch"
          else "query"
          end

    json = run!(cmd, query.to_s, "--json", "-n", limit.to_i.to_s, "-c", collection.to_s)
    JSON.parse(json)
  rescue JSON::ParserError
    []
  end

  def self.run!(*args)
    stdout, stderr, status = Open3.capture3(qmd_bin, *args.map(&:to_s))

    return stdout if status.success?

    raise Error, "qmd #{args.join(' ')} failed: #{stderr.presence || stdout.presence || status.to_s}"
  end
end
