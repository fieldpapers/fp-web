# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  username               :string(32)
#  legacy_password        :string(40)
#  email                  :string(255)
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  updated_at             :datetime
#  created_at             :datetime
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "destroying a user keeps their content, including private and failed atlases" do
    user = create_user("mapper")
    public_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    private_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    private_atlas.update_column(:private, true)
    failed_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    failed_atlas.update_column(:failed_at, Time.now)
    create_snapshot(public_atlas, "A1", "snap0001", uploader: user)
    create_snapshot(private_atlas, "A1", "snap0002", uploader: user)

    user.destroy!

    atlases = Atlas.unscoped.where(id: [public_atlas, private_atlas, failed_atlas])
    assert_equal [nil], atlases.pluck(:user_id).uniq
    assert_equal 3, atlases.count
    assert_equal [nil, nil], Snapshot.unscoped.where(slug: ["snap0001", "snap0002"]).pluck(:user_id)
  end

  test "deleting an account deletes private content and disowns public content" do
    user = create_user("mapper")
    public_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    private_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    private_atlas.update_column(:private, true)
    shared_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    shared_atlas.update_column(:private, true)
    create_snapshot(public_atlas, "A1", "pubsnap1", uploader: user)
    create_snapshot(public_atlas, "A1", "privsnap", uploader: user)
    Snapshot.unscoped.find_by!(slug: "privsnap").update_column(:private, true)
    create_snapshot(private_atlas, "A1", "onpriv01", uploader: user)
    create_snapshot(shared_atlas, "A1", "others01")

    user.delete_account!

    assert_not User.exists?(user.id)
    assert_nil Atlas.unscoped.find(public_atlas.id).user_id
    assert_not Atlas.unscoped.exists?(private_atlas.id)
    assert_nil Atlas.unscoped.find(shared_atlas.id).user_id
    assert_nil Snapshot.unscoped.find_by!(slug: "pubsnap1").user_id
    assert_equal ["others01", "pubsnap1"], Snapshot.unscoped.order(:slug).pluck(:slug)
  end
end
