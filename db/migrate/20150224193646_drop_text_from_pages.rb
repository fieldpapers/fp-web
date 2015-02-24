class DropTextFromPages < ActiveRecord::Migration
  def up
    remove_column :pages, :text
  end
end
