class DropLogs < ActiveRecord::Migration
  def up
    drop_table :logs
  end
end
