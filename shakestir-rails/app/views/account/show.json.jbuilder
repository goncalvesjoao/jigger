json.data do
  json.extract! @account, :id, :email_address, :handle, :display_name
  json.name @account.profile_name
end
