class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :title
      t.string :desc

      t.timestamps
    end
  end
end
