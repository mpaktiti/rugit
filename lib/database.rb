require "digest/sha1"
require "strscan"
require "zlib"

require_relative "./database/blob"
require_relative "./database/commit"
require_relative "./database/entry"
require_relative "./database/tree"

TEMP_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

# Manages the files in .git/objects
class Database
    TYPES = {
        "blob"   => Blob,
        "tree"   => Tree,
        "commit" => Commit
    }

    def initialize(pathname)
        @pathname = pathname
        @objects  = {}
    end

    def store(object)
        content = serialize_object(object)
        object.oid = hash_content(content)

        write_object(object.oid, content)
    end

    def hash_object(object)
        hash_content(serialize_object(object))
    end

    def load(oid)
        @objects[oid] ||= read_object(oid)
    end

    def short_oid(oid)
        oid[0..6]
    end

    private

    def serialize_object(object)
        string = object.to_s.force_encoding(Encoding::ASCII_8BIT)
        "#{ object.type } #{ string.bytesize }\0#{ string }"
        # "%s %d\0%s" % [object.type, string.bytesize, string]
    end

    def hash_content(content)
        Digest::SHA1.hexdigest(content)
    end

    def object_path(oid)
        # example object_path = /Users/maria/rugit/.git/objects/cc/628ccd10742baea8241c5924df992b5c019f71
        @pathname.join(oid[0..1], oid[2..-1])
    end

    def write_object(oid, content)
        object_path = object_path(oid)
        return if File.exist?(object_path)

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

    def read_object(oid)
        # calc object's path based on oid, read file, and decompress it
        data = Zlib::Inflate.inflate(File.read(object_path(oid)))
        scanner = StringScanner.new(data)

        # all objects begin with the object's type, then a space, then a null byte
        type = scanner.scan_until(/ /).strip
        _size = scanner.scan_until(/\0/)[0..-2]

        object = TYPES[type].parse(scanner)
        object.oid = oid

        object
    end

    def generate_temp_name
        "tmp_obj_#{ (1..6).map { TEMP_CHARS.sample }.join("") }"
    end

end