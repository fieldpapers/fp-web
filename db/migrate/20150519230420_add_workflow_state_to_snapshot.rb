class AddWorkflowStateToSnapshot < ActiveRecord::Migration
  def change
    change_table(:snapshots) do |t|
      t.string :workflow_state
    end
  end
end
