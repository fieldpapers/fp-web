class DropMessages < ActiveRecord::Migration[4.2]
  def up
    drop_table :messages
  end
end
