class Entry
    attr_reader :name, :oid

    REGULAR_MODE = "100644"
    EXECUTABLE_MODE = "100755"

    def initialize(name, oid, stat)
        @name = name
        @oid = oid
        @stat = stat
    end

    def basename
        @name.basename
    end

    def mode
        @stat.executable? ? EXECUTABLE_MODE : REGULAR_MODE
    end

    def parent_directories
        @name.descend.to_a[0..-2]
    end
end