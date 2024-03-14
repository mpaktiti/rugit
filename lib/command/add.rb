require "pathname"

require_relative "./base"
require_relative "../database/blob"
require_relative "../lockfile"
require_relative "../repository"
require_relative "../workspace"

module Command
    class Add < Base
        def run
            root_path = Pathname.new(@dir)
            repo = Repository.new(root_path.join(".git"))

            # load the existing index into memory
            begin
                repo.index.load_for_update
            rescue Lockfile::LockDenied => error
                @stderr.puts <<~ERROR
                    fatal: #{ error.message }

                    Another rugit process seems to be running in this repository.
                    Please make sure all processes are terminated then try again.
                    If it still fails, a rugit process may have crashed in this
                    repository earlier: remove the file manually to continue.
                ERROR
                exit 128
            end

            # read all paths to be added, error out if any does not exist
            begin
                paths = @args.flat_map do |path|
                    path = Pathname.new(File.expand_path(path))
                    repo.workspace.list_files(path)
                end
            rescue Workspace::MissingFile => error
                @stderr.puts "fatal: #{ error.message }"
                repo.index.release_lock
                exit 128
            end

            begin
                paths.each do |path|
                    data = repo.workspace.read_file(path)
                    stat = repo.workspace.stat_file(path)

                    # write object to database and add to index
                    blob = Database::Blob.new(data)
                    repo.database.store(blob)
                    repo.index.add(path, blob.oid, stat)
                end
            rescue Workspace::NoPermission => error
                @stderr.puts "error: #{ error.message }"
                @stderr.puts "fatal: adding files failed"
                repo.index.release_lock
                exit 128
            end

            repo.index.write_updates
            exit 0
        end
    end
end