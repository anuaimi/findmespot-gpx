require 'sqlite3'


def initialize_database(db_file)

  begin
    db = SQLite3::Database.open(db_file)

    # users table
    db.execute("CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, email TEXT NOT NULL UNIQUE, password TEXT, updated_at INTEGER NOT NULL)")
    db.execute "CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx on users(email)"

    # feeds table
    db.execute("CREATE TABLE IF NOT EXISTS feeds(id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL UNIQUE, feed_url_id TEXT, 
      feed_password TEXT, updated_at INTEGER NOT NULL)")
    db.execute "CREATE UNIQUE INDEX IF NOT EXISTS feeds_user_id_idx on feeds(user_id)"

    # events table
    db.execute "CREATE TABLE IF NOT EXISTS messages(id INTEGER PRIMARY KEY, messanger_id TEXT, messanger_name TEXT, 
      unix_time INTEGER, message_type TEXT, lat TEXT, lon TEXT, model_id TEXT, show_custom_msg TEXT, date_time TEXT, 
      battery_state TEXT, hidden TEXT, altitude INTEGER, updated_at INTEGER NOT NULL)"
    db.execute "CREATE UNIQUE INDEX IF NOT EXISTS messages_unix_time_idx on messages(unix_time)"

    # logs table
    db.execute "CREATE TABLE IF NOT EXISTS logs(id INTEGER PRIMARY KEY, code TEXT, text TEXT, description TEXT, 
      updated_at INTEGER NOT NULL)"
    db.execute "CREATE UNIQUE INDEX IF NOT EXISTS logs_updated_at_idx on logs(updated_at)"

  rescue Exception => e
    puts "error: #{e.message}"
  end

  db.close if db

end

def seed_database(db_file)

  db = SQLite3::Database.open(db_file)

  # see if db seeded
  num_rows = db.get_first_value("SELECT COUNT(*) FROM users")
  if num_rows > 0
    return
  end

  # add default users
  # updated_at = Time.now
  # db.execute("INSERT INTO users (email, password, updated_at) VALUES ('athir@nuaimi.com', 'password123', #{updated_at.to_r})")
  # user_id = db.last_insert_row_id

  begin
  rescue Exception => e
    puts "error: #{e.message}"
  end

  db.close if db

end
