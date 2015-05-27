class AddPdfUrlToPage < ActiveRecord::Migration
  def change
    change_table(:pages) do |t|
      t.string :pdf_url
    end
  end
end
