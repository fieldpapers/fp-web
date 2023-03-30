class DropForms < ActiveRecord::Migration[4.2]
  def up
    drop_table :forms
    drop_table :form_fields
  end
end
