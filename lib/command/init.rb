require "fileutils"
require "pathname"

require_relative "./base"

module Command
    class Init < Base
        def run
            # get the input directory, if null use current
            path = @args.fetch(0, @dir)

            # convert relative path to absolute
            root_path = base.expanded_pathname(path)

            git_path = root_path.join(".git")

            ["objects", "refs"].each do |dir|
                begin
                    # create dir including any parent dir that doesn't exist (like mkdir -p)
                    FileUtils.mkdir_p(git_path.join(dir))
                rescue Errno::EACCES => error
                    @stderr.puts "fatal: #{ error.message }"
                    exit 1
                end
            end

            puts "Initialized empty Rugit repository in #{ git_path }"
            exit 0
        end
    end
end