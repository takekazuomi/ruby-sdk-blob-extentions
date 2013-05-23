# -*- coding: utf-8 -*-
require 'minitest/unit'
require 'minitest/autorun'

require 'azure'

require 'azure_blob_extentions'



# http://doc.ruby-lang.org/ja/1.9.2/library/minitest=2funit.html

class BlobTest < MiniTest::Unit::TestCase
  TEST_DATAFILE_NANE = "data/file.dat"

  def create_test_blob_container
    container = nil
    begin
      container = @azure_blob_service.get_container_properties(@container_name)
    rescue Azure::Core::Http::HTTPError => e
      container = @azure_blob_service.create_container(@container_name)
    end
    return container
  end

  def create_test_blob
    content = File.open(Pathname.new(@test_local_filename), 'rb') { |file| file.read }
    @azure_blob_service.create_block_blob(@container_name, TEST_DATAFILE_NANE, content)
  end

  def setup
    Azure.configure do |config|
      config.storage_account_name = "foobarominode002"
      config.storage_access_key   = "VG1iawOENiEEfXuIe3sycANQrUcFCX5fXVa+5ZKHH2eCFSoFtOuu0adhUgUwr5tD1iciAOozkFGBdaeRrSWNeQ=="
    end
    @azure_blob_service = Azure::BlobService.new
    @container_name = "1blob-test%s" % Time.now.strftime("-%m%d%H")
    @test_local_filename = File.expand_path('../'+TEST_DATAFILE_NANE, __FILE__)

    create_test_blob_container
  end

  def xtest_blob_exists?
    create_test_blob
    r = @azure_blob_service.blob_exists? @container_name, TEST_DATAFILE_NANE
    assert_equal true, r
    r = @azure_blob_service.blob_exists? @container_name, TEST_DATAFILE_NANE+"2"
    assert_equal false, r
  end

  def test_upload_in_threads
    @azure_blob_service.parallel_upload @container_name, @test_local_filename, TEST_DATAFILE_NANE, :in_threads => 2
    r = @azure_blob_service.blob_exists? @container_name, TEST_DATAFILE_NANE
    p "%s, %s" % [@container_name, TEST_DATAFILE_NANE]
    assert_equal true,  r
  end

  def test_upload_in_processes
    skip "fork unimplemented on this machine" if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/

    blob_name = "%s.%s" % [TEST_DATAFILE_NANE, Time.now.strftime("%m%d%H%M%S")]
    @azure_blob_service.parallel_upload @container_name, @test_local_filename, blob_name, :in_processes => 2
    r = @azure_blob_service.blob_exists? @container_name, blob_name
    p "%s, %s" % [@container_name, blob_name]
    assert_equal true,  r
  end

end


