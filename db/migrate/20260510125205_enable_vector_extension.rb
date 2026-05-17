class EnableVectorExtension < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    enable_extension "vector"
  rescue ActiveRecord::StatementInvalid => error
    say "pgvector extension is unavailable; continuing with keyword search fallback. #{error.message}"
  end

  def down
    disable_extension "vector" if extension_enabled?("vector")
  end
end
