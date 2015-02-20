class DropForms < ActiveRecord::Migration
  def up
    drop_table :forms
    drop_table :form_fields
  end
end
