class RenamePrintHrefToPageUrl < ActiveRecord::Migration
  def change
    rename_column :snapshots, :print_href, :page_url
  end
end
