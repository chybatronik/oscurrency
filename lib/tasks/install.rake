require 'active_record'
require 'active_record/fixtures'

desc "Install Insoshi"
task :install => :environment do |t|
  Rake::Task["db:schema:load"].invoke
  begin
    Rake::Task["db:full_text_index"].invoke
  rescue
    puts "An error happened while installing the full text index: #{$!}."
    puts "No worries. This is expected with SQLite" if $!.to_s =~ /SQLite3/
    puts "Resuming with installation..."
  end
  Rake::Task["db:seed"].invoke
  using_email = !!(ENV['SMTP_DOMAIN'] && ENV['SMTP_SERVER']) # explicit true
  pref = Preference.first || Preference.create!(:app_name => (ENV['APP_NAME'] || "APP_NAME is Blank"), :server_name => ENV['SERVER_NAME'], :smtp_server => ENV['SMTP_SERVER'] || '', :email_notifications => using_email) 
  p = Person.new(:name => "admin", :email => "admin@example.com", :password => "admin", :password_confirmation => "admin", :description => "")
  p.save!
  p.admin = true
  p.email_verified = true
  p.save
  address = Address.new(person: p) # name is not used anywhere and cannot be mass assigned anyway
  address.save

  group_attributes = {:name => (ENV['APP_NAME'] || "Default Group"),
                      :description => "The system installation created this group with a currency and configured it as a mandatory group. All people who register on the system will automatically join all mandatory groups. By default, there is no credit limit configured for new account holders for this group although you may configure one.",
                      :mode => Group::PUBLIC,
                      :unit => 'hours',
                      :asset => 'hours',
                      :adhoc_currency => true
  }

  g = Group.new(group_attributes)
  g.owner = p
  g.save!
  g.mandatory = true
  g.save
  pref.default_group_id = g.id
  pref.save!

  p.default_group_id = g.id
  p.save!
  puts "Installation complete!"
end
