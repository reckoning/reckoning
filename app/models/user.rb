# frozen_string_literal: true

class User < ApplicationRecord
  devise :two_factor_authenticatable, :two_factor_backupable, :database_authenticatable,
    :recoverable, :lockable, :trackable, :validatable, :confirmable, :rememberable,
    :timeoutable, otp_secret_encryption_key: Rails.application.credentials.devise_otp!,
    otp_backup_code_length: 10, otp_number_of_backup_codes: 10

  belongs_to :account
  has_many :timers, dependent: :destroy

  before_save :update_gravatar_hash
  before_create :setup_otp_secret

  validates :email, email: true

  def overtime?
    account.customers.any? { |customer| customer.overtime(id) }
  end

  def weekly_hours
    timers.where("date >= ?", Time.current.beginning_of_week).sum(:value)
  end

  def daily_hours
    timers.where(date: Time.current).sum(:value)
  end

  def update_gravatar_hash
    hash = if gravatar.blank?
      Digest::MD5.hexdigest(id.to_s)
    else
      Digest::MD5.hexdigest(gravatar.downcase.strip)
    end
    self.gravatar_hash = hash
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_welcome
    token = set_reset_password_token
    UserMailer.welcome_mail(self, token).deliver
  end

  def avatar(size = 24)
    "https://www.gravatar.com/avatar/#{gravatar_hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{gravatar_hash}.png&amp;r=x&amp;s=#{size}"
  end

  # override devise trackable to not save on every single request
  def update_tracked_fields!(request)
    # We have to check if the user is already persisted before running
    # `save` here because invalid users can be saved if we don't.
    # See https://github.com/heartcombo/devise/issues/4673 for more details.
    return if new_record?

    return if updated_at < 1.minute.from_now

    update_tracked_fields(request)
    save(validate: false)
  end

  def reset_otp
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:otp_required_for_login, false)
    update_column(:encrypted_otp_secret, nil)
    update_column(:encrypted_otp_secret_iv, nil)
    update_column(:encrypted_otp_secret_salt, nil)
    update_column(:otp_backup_codes, nil)
    # rubocop:enable Rails/SkipsModelValidations
    update(otp_secret: User.generate_otp_secret)
  end

  ## TODO: remove once Deivse Two Factor upgrade to 5.x is done
  # Decrypt and return the `encrypted_otp_secret` attribute which was used in
  # prior versions of devise-two-factor
  # @return [String] The decrypted OTP secret
  private def legacy_otp_secret
    return nil unless self[:encrypted_otp_secret]
    return nil unless self.class.otp_secret_encryption_key

    hmac_iterations = 2000 # a default set by the Encryptor gem
    key = self.class.otp_secret_encryption_key
    salt = Base64.decode64(encrypted_otp_secret_salt)
    iv = Base64.decode64(encrypted_otp_secret_iv)

    raw_cipher_text = Base64.decode64(encrypted_otp_secret)
    # The last 16 bytes of the ciphertext are the authentication tag - we use
    # Galois Counter Mode which is an authenticated encryption mode
    cipher_text = raw_cipher_text[0..-17]
    auth_tag = raw_cipher_text[-16..]

    # this alrorithm lifted from
    # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

    # create an OpenSSL object which will decrypt the AES cipher with 256 bit
    # keys in Galois Counter Mode (GCM). See
    # https://ruby.github.io/openssl/OpenSSL/Cipher.html
    cipher = OpenSSL::Cipher.new("aes-256-gcm")

    # tell the cipher we want to decrypt. Symmetric algorithms use a very
    # similar process for encryption and decryption, hence the same object can
    # do both.
    cipher.decrypt

    # Use a Password-Based Key Derivation Function to generate the key actually
    # used for encryptoin from the key we got as input.
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

    # set the Initialization Vector (IV)
    cipher.iv = iv

    # The tag must be set after calling Cipher#decrypt, Cipher#key= and
    # Cipher#iv=, but before calling Cipher#final. After all decryption is
    # performed, the tag is verified automatically in the call to Cipher#final.
    #
    # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
    cipher.auth_tag = auth_tag

    # auth_data must be set after auth_tag has been set when decrypting See
    # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
    # we are not adding any authenticated data but OpenSSL docs say this should
    # still be called.
    cipher.auth_data = ""

    # #update is (somewhat confusingly named) the method which actually
    # performs the decryption on the given chunk of data. Our OTP secret is
    # short so we only need to call it once.
    #
    # It is very important that we call #final because:
    #
    # 1. The authentication tag is checked during the call to #final
    # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
    #    to call #final to get it to process the last chunk properly. The output
    #    of #final should be appended to the decrypted value. This isn't
    #    required for streaming cipher modes but including it is a best practice
    #    so that your code will continue to function correctly even if you later
    #    change to a block cipher mode.
    cipher.update(cipher_text) + cipher.final
  end
end
