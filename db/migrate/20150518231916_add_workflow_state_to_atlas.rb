class AddWorkflowStateToAtlas < ActiveRecord::Migration
  def change
    change_table(:atlases) do |t|
      t.string :workflow_state
    end
  end
end
