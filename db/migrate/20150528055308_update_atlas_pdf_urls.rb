class UpdateAtlasPdfUrls < ActiveRecord::Migration[4.2]
  def up
    execute <<-EOQ
      UPDATE atlases
      SET pdf_url=CONCAT('http://s3.amazonaws.com/files.fieldpapers.org/atlases/', slug, '/walking-paper-', slug, '.pdf')
      WHERE pdf_url REGEXP 'fieldpapers.org/files/prints/.+/walking'
    EOQ
    execute <<-EOQ
      UPDATE atlases
      SET pdf_url=CONCAT('http://s3.amazonaws.com/files.fieldpapers.org/atlases/', slug, '/field-paper-', slug, '.pdf')
      WHERE pdf_url REGEXP 'fieldpapers.org/files/prints/.+/field'
    EOQ
  end
end
