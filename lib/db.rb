require 'dotenv'
module DB
  def db
    @db ||= begin
      Dotenv.load
      url = "postgres://#{ENV['DBUSER']}:#{ENV['DBPASSWORD']}@#{ENV['DBHOST']}/#{ENV['DBNAME']}"
      Sequel.connect(url)
    end
  end
end
