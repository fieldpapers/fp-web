# Status is derived from composed_at/decoded_at and failed_at.
class RemoveWorkflowState < ActiveRecord::Migration[7.2]
  def change
    remove_column :atlases, :workflow_state, :string
    remove_column :snapshots, :workflow_state, :string
  end
end
