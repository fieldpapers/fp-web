class DropLogs < ActiveRecord::Migration[4.2]
  def up
    drop_table :logs
  end
end
