class AddUniqueIndexesForSlugs < ActiveRecord::Migration[4.2]
  def up
    remove_index :atlases, :slug
    remove_index :snapshots, :slug

    add_index :atlases, :slug, unique: true
    add_index :snapshots, :slug, unique: true
  end
end
