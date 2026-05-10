class KnowledgeSource < ApplicationRecord
  SOURCE_TYPES = %w[manual website document].freeze
  STATUSES = %w[draft processing ready failed].freeze
  CHUNK_MAX_LENGTH = 1_200

  belongs_to :agent
  has_many :knowledge_chunks, dependent: :destroy

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :title, presence: true
  validates :raw_content, presence: true, if: :manual?

  def manual?
    source_type == "manual"
  end

  def rebuild_chunks!
    transaction do
      knowledge_chunks.destroy_all

      build_chunks.each_with_index do |content, index|
        knowledge_chunks.create!(
          agent: agent,
          content: content,
          position: index,
          embedding_model: KnowledgeChunk::EMBEDDING_MODEL
        )
      end

      update!(status: "ready")
    end
  end

  private

  def build_chunks
    normalized_content
      .split(/\n{2,}/)
      .flat_map { |paragraph| split_long_text(paragraph) }
      .map(&:strip)
      .reject(&:blank?)
  end

  def normalized_content
    raw_content.to_s
      .gsub(/\r\n?/, "\n")
      .split(/\n{2,}/)
      .map { |paragraph| paragraph.lines.map(&:strip).reject(&:blank?).join(" ") }
      .reject(&:blank?)
      .join("\n\n")
  end

  def split_long_text(text)
    return [text] if text.length <= CHUNK_MAX_LENGTH

    text.scan(/.{1,#{CHUNK_MAX_LENGTH}}(?:\s+|$)/m).map(&:strip)
  end
end
