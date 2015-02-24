class AddAttachmentSceneToSnapshots < ActiveRecord::Migration
  def self.up
    change_table :snapshots do |t|
      t.attachment :scene
      t.string :s3_scene_url
    end
  end

  def self.down
    remove_column :snapshots, :s3_scene_url
    remove_attachment :snapshots, :scene
  end
end
