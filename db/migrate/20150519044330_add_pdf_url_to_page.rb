class AddPdfUrlToPage < ActiveRecord::Migration[4.2]
  def change
    change_table(:pages) do |t|
      t.string :pdf_url
    end
  end
end
