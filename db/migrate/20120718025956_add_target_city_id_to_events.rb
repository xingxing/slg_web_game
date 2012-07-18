class AddTargetCityIdToEvents < ActiveRecord::Migration
  def change
    add_column :events , :target_city_id ,:integer
  end
end
