require 'digest/sha1'

## Helper mixin for command classes to use.
module CommandHelper

  ##
  # Base name for generated filenames, derived from directory name.
  # By convention I chop off anything in round brackets at the end as I use this
  # to indicate the state of a series currently.
  #
  def basename
    name = File.basename(Dir.pwd)
    name.gsub!(/\s+\([^\(\)]+\)$/, '')
    name
  end

  ##
  # Attempts to guess the number of digits used for naming the files.
  # If there is already a named file present it will copy that one.
  # Otherwise it will default to 2.
  #
  # If files are not named consistently then this raises an error.
  #
  def digits
    result = nil
    each_episode_file do |file, num_str|
      digits_for_file = num_str.length
      if result && result != digits_for_file
        raise Exception, "Files are not consistently named."
      end
      result = digits_for_file
    end
    result ||= 2
    result
  end

  ##
  # Iterates over episode filenames.
  #
  def each_episode_file
    episode_filename_regex ||= Regexp.compile("^#{Regexp.escape(basename)} - (\\d+)\\.[^.]+$")
    exclude_episode_filename_regex ||= Regexp.compile("^#{Regexp.escape(basename)} - (\\d+)\\.(ass|ssa|sub)$")
    Dir.entries('.').sort.each do |file|
      if file =~ episode_filename_regex
        episode_number = $1
        if !(file =~ exclude_episode_filename_regex)
          yield file, episode_number
        end
      end
    end
  end

  ## Generates the filename for a given episode number.
  def episode_filename(num, origfile)
    num_str = "%0#{digits}d" % num
    if origfile =~ /^.*(\.[^\.]+$)/
      extension = $1
    else
      extension = ''
    end

    "#{basename} - #{num_str}#{extension}"
  end

  ## Generates the filename for the digest file.
  def digest_filename
    "#{basename}.sha1"
  end

  ## Gets the name of the org config file.
  def config_filename
    "0org"
  end

  ## Generates multiple hashes on the given filename
  ##
  ## Supports:
  ##   :crc32
  ##   :sha1
  ##
  def hashes_for(filename, hash_names)
    digests = hash_names.map do |name|
      case name
        when :crc32
          PseudoDigestCrc32.new
        when :sha1
          Digest::SHA1.new
        else
          raise ArgumentError, "Unknown digest name: #{name}"
      end
    end

    File.open(filename) do |io|
      buf = String.new
      until io.eof?
        io.read(8*1024*1024, buf)

        digests.each { |digest| digest.update(buf) }
      end
    end

    digests.map { |digest| Digest.hexencode(digest.digest) }
  end

  class PseudoDigestCrc32
    def initialize
      @value = Zlib.crc32()
    end

    def update(buf)
      @value = Zlib.crc32(buf, @value)
    end

    def digest
      [@value].pack("N")
    end
  end

  ## Generates an SHA-1 digest and encoded it as lowercase hex (the standard for sha1sum format)
  def sha1_hex(filename)
    puts "DEPRECATION: sha1_hex is deprecated, use hashes_for instead."
    digests_for(filename, [:sha1])
  end
  
  ## Generates a CRC-32 in uppercase hex, the convention for apps such as cksfv.
  def crc32_hex(filename)
    puts "DEPRECATION: crc32_hex is deprecated, use hashes_for instead."
    digests_for(filename, [:crc32])
  end
end
