class KnowledgeEmbedding
  class << self
    def available?
      ENV["OPENAI_API_KEY"].present?
    end

    def embed(text)
      return if text.blank? || !available?

      embedding = RubyLLM.embed(
        text,
        model: KnowledgeChunk::EMBEDDING_MODEL,
        dimensions: KnowledgeChunk::EMBEDDING_DIMENSIONS
      )
      vector = embedding_vector(embedding)
      return if vector.blank?

      embedding
    end

    def vector_sql(embedding)
      vector = embedding_vector(embedding)
      return if vector.blank?

      quoted_vector = ActiveRecord::Base.connection.quote(vector_to_database(vector))
      Arel.sql("#{quoted_vector}::vector")
    end

    def vector_to_database(vector)
      return if vector.blank?

      "[#{vector.join(",")}]"
    end

    def embedding_vector(embedding)
      return embedding if embedding.is_a?(Array)
      return if embedding.blank? || !embedding.respond_to?(:vectors)

      embedding.vectors
    end
  end
end
