class PrepareUsersForOsmLogin < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :osm_id, :bigint
    add_index :users, :osm_id, unique: true

    # OSM display names can be up to 255 characters
    reversible do |dir|
      dir.up { change_column :users, :username, :string, limit: 255 }
      dir.down { change_column :users, :username, :string, limit: 32 }
    end
  end
end
