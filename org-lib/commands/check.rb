require 'zlib'
require 'fileutils'

class CheckCommand < Command
  include CommandHelper

  def usage
    <<EOT

Usage: org check

  Checks digests in the current directory.

EOT
  end

  def run(*args)
    checked_files = digest_check
    if checked_files.nil?
      return 1
    end

    Dir.entries('.').sort.each do |file|
      if file != digest_filename and file != '.' and file != '..' and
         file != config_filename and
         !checked_files.include?(file)
        $stderr.puts "Unchecked file: #{file}"
      end
    end

    0
  end

  # Performs a check of the digests of all files in the .sha1 file.
  # Returns the list of filenames which were checked, nil if failed.
  def digest_check
    checked_files = []
    all_ok = true

    File.open(digest_filename) do |io|
      io.each_line do |line|
        if line =~ /^([0-9a-fA-Z]{40})  (.*)?/
          expected_sha1 = $1
          filename = $2

          if checked_files.include?(filename)
            $stderr.puts "Warning: duplicate file entry in .sha1 file: #{filename}"
          end

          checked_files << filename

          $stderr.print "Checking #{filename} ... "
          if expected_sha1 == sha1_hex(filename)
            $stderr.puts "OK"
          else
            $stderr.puts "NOT OK: #{filename}"
            all_ok = false
          end
        end
      end
    end

    all_ok ? checked_files : nil
  end
end
