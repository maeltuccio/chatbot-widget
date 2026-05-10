class KnowledgeChunk < ApplicationRecord
  EMBEDDING_MODEL = "text-embedding-3-small"
  EMBEDDING_DIMENSIONS = 1536

  belongs_to :agent
  belongs_to :knowledge_source

  validates :content, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: :knowledge_source_id }
  validates :embedding_model, presence: true
end
