class AddWorkflowStateToSnapshot < ActiveRecord::Migration[4.2]
  def change
    change_table(:snapshots) do |t|
      t.string :workflow_state
    end
  end
end
