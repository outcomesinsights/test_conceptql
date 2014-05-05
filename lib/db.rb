require 'dotenv'
module DB
  def db
    @db ||= begin
      Dotenv.load
      url = "postgres://#{ENV['DBUSER']}:#{ENV['DBPASSWORD']}@#{ENV['DBHOST']}/#{ENV['DBNAME']}"
      after_connect = Proc.new { |conn| conn.execute("SET search_path TO #{ENV['BM_DBSCHEMA']},vocabulary,public")}
      Sequel.connect(url, after_connect: after_connect)
    end
  end
end
