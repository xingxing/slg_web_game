class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|

      t.timestamps
    end
  end
end
