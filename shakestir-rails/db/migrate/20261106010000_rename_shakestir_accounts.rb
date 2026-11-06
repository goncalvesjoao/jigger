class RenameShakestirAccounts < ActiveRecord::Migration[8.1]
  class Account < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    rename_accounts("jigger", "shakestir", "Jigger", "ShakeStir")
  end

  def down
    rename_accounts("shakestir", "jigger", "ShakeStir", "Jigger")
  end

  private

  def rename_accounts(previous, current, previous_name, current_name)
    Account.where(system_key: previous).each do |account|
      attributes = { system_key: current, handle: current }
      attributes[:email_address] = "#{current}@#{current}.example" if account.email_address == "#{previous}@#{previous}.example"
      attributes[:display_name] = current_name if account.display_name == previous_name
      if account.bio == "Recipes shared by #{previous_name}. Source credits are preserved on each recipe."
        attributes[:bio] = "Recipes shared by #{current_name}. Source credits are preserved on each recipe."
      end
      account.update!(attributes)
    end

    %w[leo alex].each do |demo|
      Account.where(email_address: "#{demo}@#{previous}.example").update_all(email_address: "#{demo}@#{current}.example")
    end
  end
end
