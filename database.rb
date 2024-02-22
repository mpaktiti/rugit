require "digest/sha1"
require "zlib"

require_relative "./blob"

TEMP_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

# Manages the files in .git/objects
class Database
    def initialize(pathname)
        @pathname = pathname
    end

    def store(object)
        string = object.to_s.force_encoding(Encoding::ASCII_8BIT)
        content = "#{ object.type } #{ string.bytesize }\0#{ string}"
        # "%s %d\0%s" % [object.type, string.bytesize, string]

        object.oid = Digest::SHA1.hexdigest(content)
        write_object(object.oid, content)
    end

    private

    def write_object(oid, content)
        # example object_path = /Users/maria/rugit/.git/objects/cc/628ccd10742baea8241c5924df992b5c019f71
        object_path = @pathname.join(oid[0..1], oid[2..-1])
        dirname = object_path.dirname
        temp_path = dirname.join(generate_temp_name)

        begin
            # RDWR: open file for read and write
            # CREAT: create file if it doesn't exist
            # EXCL: throw error if file exists
            flags = File::RDWR | File::CREAT | File::EXCL
            file = File.open(temp_path, flags)
        rescue Errno::ENOENT
            Dir.mkdir(dirname)
            file = File.open(temp_path, flags)
        end

        compressed = Zlib::Deflate.deflate(content, Zlib::BEST_SPEED)
        file.write(compressed)
        file.close

        File.rename(temp_path, object_path)
    end

    def generate_temp_name
        "tmp_obj_#{ (1..6).map { TEMP_CHARS.sample }.join("") }"
    end
end