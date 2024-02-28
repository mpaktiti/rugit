class Database
    class Blob
        # stores the blob's SHA-1 object ID
        attr_accessor :oid

        def initialize(data)
            @data = data
        end

        def type
            "blob"
        end

        def to_s
            @data
        end
    end
end