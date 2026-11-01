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
end
