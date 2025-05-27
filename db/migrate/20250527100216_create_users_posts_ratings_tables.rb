class CreateUsersPostsRatingsTables < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :login, null: false

      t.timestamps
    end
    add_index :users, :login, unique: true

    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.string :ip, null: false

      t.timestamps
    end

    create_table :ratings do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE ratings
      ADD CONSTRAINT value_between_1_and_5 CHECK (value >= 1 AND value <= 5);
    SQL

    add_index :ratings, [ :post_id, :user_id ], unique: true
  end
end
