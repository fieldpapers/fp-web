class AddFailedAtToAtlases < ActiveRecord::Migration[4.2]
  def change
    change_table(:atlases) do |t|
      t.datetime :failed_at
    end
  end
end
