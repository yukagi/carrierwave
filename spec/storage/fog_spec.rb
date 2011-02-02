# encoding: utf-8

require 'spec_helper'
require 'open-uri'

require 'fog'

unless ENV['FOG_MOCK'] == 'false'
  Fog.mock!
end

# figure out what tests should be runnable (based on available credentials and mocks)
credentials = []
if Fog.mocking?
  mappings = {
    'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
    'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
#    'Local'     => [:local_root],
#    'Rackspace' => [:rackspace_api_key, :rackspace_username]
  }

  for provider, keys in mappings
    data = {:provider => provider}
    for key in keys
      data[key] = key.to_s
    end
    credentials << data
  end
else
  Fog.credential = :carrierwave

  mappings = {
    'AWS'       => [:aws_access_key_id, :aws_secret_access_key],
    'Google'    => [:google_storage_access_key_id, :google_storage_secret_access_key],
    'Local'     => [:local_root],
    'Rackspace' => [:rackspace_api_key, :rackspace_username]
  }

  for provider, keys in mappings
    unless (creds = Fog.credentials.reject {|key, value| ![*keys].include?(key)}).empty?
      data = {:provider => provider}
      for key in keys
        data[key] = creds[key]
      end
      credentials << data
    end
  end
end

ENV['CARRIERWAVE_DIRECTORY'] ||= "carrierwave#{Time.now.to_i}"

# run everything we have credentials for
for credential in credentials
  fog_tests(credential)
end

# cleanup the directories and files we created
at_exit do
  # cleanup
  for credential in credentials
    storage = Fog::Storage.new(credential)
    directory = storage.directories.new(:key => ENV['CARRIERWAVE_DIRECTORY'])
    for file in directory.files
      file.destroy
    end
    directory.destroy
  end
end
