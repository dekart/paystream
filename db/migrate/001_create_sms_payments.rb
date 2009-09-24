class CreateSmsPayments < ActiveRecord::Migration
  def self.up
    create_table :sms_payments do |t|
      t.integer   :sms_id
      t.integer   :number

      t.string    :message

      t.string    :operator_name, :limit => 20
      t.integer   :operator_id

      t.float     :income
      t.string    :currency, :limit => 3

      t.string    :user_number
      t.float     :user_cost
      t.string    :user_currency, :limit => 3
      t.integer   :country_id
      
      t.boolean   :trust
      t.integer   :logic

      t.boolean   :confirmed

      t.datetime  :sent_at
      t.timestamps
    end
  end

  def self.down
    drop_table :sms_payments
  end
end
