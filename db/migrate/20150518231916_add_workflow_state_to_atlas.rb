class AddWorkflowStateToAtlas < ActiveRecord::Migration[4.2]
  def change
    change_table(:atlases) do |t|
      t.string :workflow_state
    end
  end
end
