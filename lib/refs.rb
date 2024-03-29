require_relative "./lockfile"

class Refs
    LockDenied = Class.new(StandardError)

    def initialize(pathname)
        @pathname = pathname
    end

    def update_head(oid)
        lockfile = Lockfile.new(head_path)

        lockfile.hold_for_update
        lockfile.write(oid)
        lockfile.write("\n")
        lockfile.commit
    end

    def read_head
        if File.exist?(head_path)
            File.read(head_path).strip
        end
    end

    def head_path
        @pathname.join("HEAD")
    end
end