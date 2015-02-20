class RenameCreatedInUsers < ActiveRecord::Migration
  def change
    change_table(:users) do |t|
      t.datetime :created_at
    end

    execute "UPDATE users SET created_at = created"

    change_table(:users) do |t|
      t.remove :created
    end
  end
end
