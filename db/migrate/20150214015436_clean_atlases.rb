class CleanAtlases < ActiveRecord::Migration[4.2]
  def change
    rename_table :prints, :atlases

    execute("ALTER TABLE atlases CHANGE created created_at TIMESTAMP")
    execute("ALTER TABLE atlases CHANGE composed composed_at TIMESTAMP")

    change_table(:atlases) do |t|
      t.datetime :updated_at
    end

    execute("DROP VIEW IF EXISTS new_atlases")
  end
end
