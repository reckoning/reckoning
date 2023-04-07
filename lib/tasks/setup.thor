# frozen_string_literal: true

require "highline/import"

class Setup < Thor
  include Thor::Actions

  desc "admin", "Create Admin-User"
  option :email, type: :string, default: nil
  option :password, type: :string, default: nil
  option :password_confirmation, type: :string, default: nil
  def admin
    require "./config/environment"

    if options.include?("email")
      email = options[:email]
      password = options[:password]
      password_confirmation = options[:password_confirmation]
    else
      email = HighLine.ask("E-Mail: ")
      if email.blank?
        puts "E-Mail can't be blank!"
        exit
      end
      password = HighLine.ask("Password: ") { |q| q.echo = "*" }
      if password.blank?
        puts "Password can't be blank!"
        exit
      end
      password_confirmation = HighLine.ask("Password (again): ") { |q| q.echo = "*" }
    end

    if password_confirmation != password
      puts "Passwords dont match!"
      exit
    end

    user = User.new(email: email, password: password, password_confirmation: password_confirmation, admin: true)
    user.skip_confirmation!
    if user.save
      puts "Admin User created!"
    else
      puts "Could not create Admin-User!"
      user.errors.each do |error, message|
        puts "#{error}: #{message}"
      end
    end
  end
end
