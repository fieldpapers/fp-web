class DropMessages < ActiveRecord::Migration
  def up
    drop_table :messages
  end
end
