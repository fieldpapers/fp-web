# Usernames aren't necessarily unique. An OSM username might collide with a legacy
# account username, or with another OSM user (if that user changed their name and
# Field Papers doesn't know about the change)
class RemoveUsernameUniqueness < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, :username, name: "username", unique: true
  end
end
