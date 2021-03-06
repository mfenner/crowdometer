class AddPostRatingCountColumn < ActiveRecord::Migration
  def self.up
    change_table(:posts) do |t|
      t.integer :ratings_count
    end
  end

  def self.down
    change_table(:posts) do |t|
      t.remove :ratings_count
    end
  end
end
