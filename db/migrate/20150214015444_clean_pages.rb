class CleanPages < ActiveRecord::Migration[4.2]
  def change
    execute("ALTER TABLE pages CHANGE created created_at TIMESTAMP")
    execute("ALTER TABLE pages CHANGE composed composed_at TIMESTAMP")

    change_table(:pages) do |t|
      t.datetime :updated_at
    end

    execute("DROP VIEW IF EXISTS new_pages")
  end
end
