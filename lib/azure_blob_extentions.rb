require 'rubygems'
require 'bundler/setup'
require 'azure'
require 'parallel'
require 'digest/md5'
require 'base64'

module Azure
  module Blob
    class BlobService < Service::StorageService

      # TODO options check
      def parallel_upload(container_name, file_name, blob_name, options = {})
        block_list = []
        mutex = Mutex.new
        block_id_prefix = Time.now.strftime("BID_%m%d%H%M%S_")

        Parallel.each(file_chunker(file_name, BLOB_BLOCK_SIZE, true), options) {
          | id, chunk |

          block_id = "%s_%010d" % [block_id_prefix, id]

          mutex.synchronize {
            block_list.push([block_id])
          }
          block_upload(container_name, blob_name, block_id, chunk)
        }

        tries = 0
        begin
          result = commit_blob_blocks(container_name, blob_name, block_list.sort, options);
        rescue Azure::Core::Http::HTTPError => ex
          if (tries < MAX_TRIES && ex.status_code != 404) # TODO check retriable error
            sleep(2**tries)
            retry
          else
            raise
          end
        end
      end

      def blob_exist?(container_name, blob, options={})
        get_blob_properties(container_name, blob, options)
      rescue Azure::Core::Http::HTTPError => ex
        raise if ex.status_code != 404
        false
      else
        true
      end


      private
      def file_chunker(file_name, chunk_size, useDup)
        chunker = Enumerator.new do |y|
          File.open(file_name, "rb") { |source|
            id = 1
            content = "x" * chunk_size
            while source.read(chunk_size, content)
              y <<  [id, content.dup] if useDup
              y <<  [id, content]     if !useDup
              id = id + 1
            end
          }
        end
      end

      def block_upload(container_name, blob_name, block_id, chunk, options={})
        tries = 0
        begin
          source_md5 = Base64.strict_encode64(Digest::MD5.digest(chunk))
          tries += 1
          server_md5 = create_blob_block(container_name, blob_name, block_id, chunk,options)

          raise RuntimeError, MD5_ERROR if source_md5 != source_md5

        rescue RuntimeError
          puts "#{$!.class}:#{$!.message}"
          if (tries < MAX_TRIES && $!.message == MD5_ERROR)
            sleep(2**tries)
            retry
          else
            raise
          end
        end
      end

      BLOB_BLOCK_SIZE = 1024 * 1024 * 4
      BLOB_TIMEOUT = 30 * 4
      MD5_ERROR = "md5 mismatch"
      MAX_TRIES = 4

    end
  end
end
