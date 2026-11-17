#!/usr/bin/env ruby

require "tempfile"
require "json"
require "net/http"
require "openssl"
require "perfect_toml"

hostname = `hostname -s`.strip

config = PerfectTOML.load_file(File.expand_path("~/etc/rekey.toml"))

valid_provisioner_keys = %w[url principals not_after]
config["provisioner"].each do |provisioner, provisioner_config|
  error = false
  provisioner_config.keys.all? do |k|
    unless valid_provisioner_keys.include?(k)
      puts "error: invalid key in provisioner '#{provisioner}' '#{k}' - only url, principals, and not_after are allowed"
      error = true
    end
  end
  exit 1 if error
end

config["key"].each do |title, key_config|
  known_keytypes = %w[dsa ecdsa ecdsa-sk ed25519 ed25519-sk rsa]
  if key_config["key"]
    key = File.expand_path(key_config["key"])
  else
    if known_keytypes.include?(title)
      key = File.expand_path("~/.ssh/id_#{title.sub("-sk", "_sk")}")
    else
      puts "error: unknown keytype '#{title}' in rekey.toml without 'key' specified"
      exit 1
    end
  end
  pkey = "#{key}.pub"
  if !File.exist?(pkey)
    puts "warning: public key file '#{pkey}' not found, skipping '#{title}'"
    next
  end
  cert = "#{key}-cert.pub"
  provisioner = key_config["provisioner"]
  provisioner_config = config["provisioner"][provisioner]
  url = provisioner_config["url"]
  if url.nil?
    puts "error: url is required for provisioner '#{provisioner}'"
    exit 1
  end
  principals = provisioner_config["principals"]
  not_after = provisioner_config["not_after"]

  Tempfile.open("roots.pem") do |root|
    uri = URI(url + "/roots.pem")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code == "200"
      File.write(root.path, response.body)
    else
      puts "unable to retrieve roots.pem"
      next
    end

    need_cert = false
    Tempfile.open("json") do |json|
      unless File.exist?(cert)
        need_cert = true
        break
      end
      unless system("step ssh inspect '#{cert}' --format json > '#{json.path}'")
        puts "unable to inspect the cert file!"
        need_cert = true
        break
      end

      valid = JSON.parse(File.read(json.path))["ValidBefore"]

      if system("step ssh needs-renewal '#{cert}' 2>/dev/null") == true
        puts "certificate needs renewal: (#{valid})"
        need_cert = true
        break
      end
      unless need_cert
        puts "certificate is valid until #{valid}, no renewal needed"
      end
    end
    if need_cert
      princ_list = principals ? principals : [ENV["USER"]]
      princ = princ_list.map { |p| "--principal #{p}" }.join(" ")

      hostname_val = `hostname`.strip
      force_flag = File.exist?(cert) ? "--force" : ""
      not_after_flag = not_after ? %(--not-after "#{not_after}") : ""
      cert_cmd = %(step ssh certificate --sign --provisioner "#{provisioner}" --ca-url "#{url}" --root "#{root.path}" #{princ} #{not_after_flag} #{force_flag} "#{ENV["USER"]}"@#{hostname_val} "#{pkey}")
      system(cert_cmd)
    end
  end
end
