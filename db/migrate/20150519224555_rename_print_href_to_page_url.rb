class RenamePrintHrefToPageUrl < ActiveRecord::Migration[4.2]
  def change
    rename_column :snapshots, :print_href, :page_url
  end
end
