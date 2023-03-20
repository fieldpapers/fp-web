class DropTextFromPages < ActiveRecord::Migration[4.2]
  def up
    remove_column :pages, :text
  end
end
