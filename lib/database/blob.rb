class Database
    class Blob
        # stores the blob's SHA-1 object ID
        attr_accessor :oid
        attr_reader   :data

        def initialize(data)
            @data = data
        end

        def type
            "blob"
        end

        def to_s
            @data
        end

        def self.parse(scanner)
            Blob.new(scanner.rest)
        end
    end
end