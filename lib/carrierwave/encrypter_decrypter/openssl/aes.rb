module Openssl
  module Aes
    def self.encrypt_for(obj)
      begin
        model = obj.model
        cipher = OpenSSL::Cipher.new("AES-#{Carrierwave::EncrypterDecrypter.configuration.key_size}-CBC")
        cipher.encrypt
        iv = model.iv || cipher.random_iv
        model.iv = iv
        cipher.iv = iv
        key = model.key || cipher.random_key
        model.key = key
        cipher.key = key
        model.save! if model.key_changed? || model.iv_changed?

        original_file_path = File.expand_path(obj.store_path, obj.root)
        encrypted_file_path = File.expand_path(obj.store_path, obj.root) + ".enc"
        buf = ""
        File.open(encrypted_file_path, "wb") do |outf|
          File.open(obj.file.path, "rb") do |inf|
            while inf.read(4096, buf)
              outf << cipher.update(buf)
            end
            outf << cipher.final
          end
        end
        File.unlink(obj.file.path)
      rescue Exception => e
        puts "****************************#{e.message}"
        puts "****************************#{e.backtrace.inspect}"
      end
    end

    def self.decrypt_for(obj,opts)
      begin
        model = obj
        if opts.key?(:filename)
          filename = opts[:filename]
        else
          mounted_as = opts[:mounted_as]
          filename = obj.send(mounted_as).root + obj.send(mounted_as).url
        end

        cipher = OpenSSL::Cipher.new("AES-#{Carrierwave::EncrypterDecrypter.configuration.key_size}-CBC")
        cipher.decrypt
        cipher.iv = model.iv
        cipher.key = model.key
        buf = ""

        original_file_path =  filename
        encrypted_file_path =  filename  + ".enc"

        File.open(original_file_path, "wb") do |outf|
          File.open(encrypted_file_path, "rb") do |inf|
            while inf.read(4096, buf)
              outf << cipher.update(buf)
            end
            outf << cipher.final
          end
        end
      rescue Exception => e
        puts "****************************#{e.message}"
        puts "****************************#{e.backtrace.inspect}"
      end
    end
  end
end
