require 'zlib'
require 'fileutils'


class ImportCommand < Command
  include CommandHelper

  class FileInfo
    attr_accessor :path
    attr_accessor :crc32
    attr_accessor :sha1

    def initialize(path)
      @path = path
    end
  end

  def usage
    <<EOT

Usage: org import [-nN] files...

  Imports multiple files to new episodes.  Performs CRC checking if the filename appears to contain
  a CRC, moves the file to the current directory under the configured naming scheme for the current
  directory, and performs an SHA-1 hash on the file.

    N - the first episode number.  The first file will receive this number; subsequent files
        will be assumed to be in order on the command-line.  For sanity's sake this command
        also checks that the number is in the file before doing any work.

        If this parameter is omitted, the numbering will start from the first file which does
        not already exist.

    files     - the list of files to export, minimum of one required to do anything useful.

EOT
  end

  def run(*args)
    raise ArgumentError if args.length < 1

    if args[0] =~ /^-n(.*)$/
      start_num = $1.to_i
      args.shift
    else
      start_num = next_number_in_series
    end

    raise ArgumentError if start_num < 1
    files = args.map { |arg| FileInfo.new(arg) }

    return 1 unless sanity_check(start_num, files)
    return 1 unless perform_moves(start_num, files)
    0
  end

  # Performs a sanity check on the files, ensuring that each contains the corresponding number,
  # that any present CRCs check out, and that, of course, the file exists.
  def sanity_check(start_num, files)
    num = start_num
    files.each do |file|
      unless File.exists?(file.path)
        $stderr.puts "File not found: #{file.path}"
        return false
      end

      unless numbers_in_filename(file.path).include?(num)
        $stderr.puts "File doesn't contain the number #{num}: #{file.path}"
        return false
      end

      unless file.path =~ /^.*(\.[^\.]+$)/
        $stderr.puts "File doesn't have an extension: #{file.path}"
        return false
      end

      destfile = episode_filename(num, file.path)
      if File.exists?(destfile)
        $stderr.puts "Destination file exists: #{destfile}"
        return false
      end

      num = num + 1
    end

    files.each do |file|
      algorithms = [:sha1]
      expected_crc = nil

      if file.path =~ /\[([0-9a-fA-F]{8})\]/
        algorithms << :crc32
        expected_crc = $1.downcase
      end

      $stderr.puts "Computing digests for: #{file.path} ... "
      hashes = hashes_for(file.path, algorithms)

      (file.sha1, file.crc32) = hashes

      $stderr.puts " SHA-1: #{hashes[0]}"

      if file.path =~ /\[([0-9a-fA-F]{8})\]/
        actual_crc = hashes[1]
        $stderr.print " CRC-32: #{actual_crc}"

        if actual_crc == expected_crc
          $stderr.puts " OK"
        else
          $stderr.puts " NOT OK (expected #{expected_crc})"
          return false
        end
      end
    end

    true
  end

  # Performs a sanity check on the files, ensuring that each contains the corresponding number,
  # that any present CRCs check out, and that, of course, the file exists.
  def perform_moves(start_num, files)
    num = start_num
    files.each do |file|
      # TODO: Generate and store the destination file on initial check so that we don't have to do it twice.
      destfile = episode_filename(num, file.path)

      File.open(digest_filename, "a") do |io|
        io.puts "#{file.sha1}  #{destfile}"
      end

      $stderr.puts "Moving: #{file.path} -> #{destfile}"
      FileUtils.mv(file.path, destfile)

      num = num + 1
    end

    true
  end

private

  ##
  # Extracts all numbers from a filename, returning an array of them.
  # Does not consider CRCs even if they consist solely of digits.
  # 
  def numbers_in_filename(filename)
    tmp = filename.gsub(/\[[0-9a-fA-F]{8}\]/, '')
    tmp.scan(/\d+/).map { |s| s.to_i }
  end

  ##
  # Attempts to determine the next episode number based on existing files.
  #
  # We also sanity check that all numbers are present.  If there is a gap then
  # we don't support autonumbering yet.
  #
  def next_number_in_series
    next_num = 1
    each_episode_file do |file, num_str|
      num = num_str.to_i
      if num != next_num
        raise Exception, "Files are not consistently numbered; expected #{next_num} but found #{num}."
      else
        next_num = num + 1
      end
    end
    next_num
  end
end

