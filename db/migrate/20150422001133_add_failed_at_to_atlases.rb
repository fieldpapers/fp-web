class AddFailedAtToAtlases < ActiveRecord::Migration
  def change
    change_table(:atlases) do |t|
      t.datetime :failed_at
    end
  end
end
