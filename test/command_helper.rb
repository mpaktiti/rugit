require "fileutils"
require "pathname"

require "command"
require "repository"

module CommandHelper
    # start every test with a new repo and delete it at the end
    def self.included(suite)
        suite.before { rugit_cmd "init", repo_path.to_s }
        suite.after { FileUtils.rm_rf(repo_path) }
    end

    def repo_path
        Pathname.new(File.expand_path("../test-repo", __FILE__))
    end

    def repo
        # repo is memoised in case we need to use it to access stateful objects
        @repository ||= Repository.new(repo_path.join(".git"))
    end

    def write_file(name, contents)
        path = repo_path.join(name)
        FileUtils.mkdir_p(path.dirname)

        flags = File::RDWR | File::CREAT | File::TRUNC
        File.open(path, flags) { |file| file.write(contents) }
    end

    def set_env(key, value)
        @env ||= {}
        @env[key] = value
    end

    def set_stdin(string)
        @stdin = StringIO.new(string)
    end

    def rugit_cmd(*argv)
        @env ||= {}
        @stdin ||= StringIO.new
        @stdout = StringIO.new
        @stderr = StringIO.new

        @cmd = Command.execute(repo_path.to_s, @env, argv, @stdin, @stdout, @stderr)
    end

    def commit(message)
        set_env("GIT_AUTHOR_NAME", "Maria Paktiti")
        set_env("GIT_AUTHOR_EMAIL", "author@example.com")
        set_stdin(message)
        rugit_cmd("commit")
    end

    def make_executable(name)
        File.chmod(0755, repo_path.join(name))
    end

    def make_unreadable(name)
        File.chmod(0200, repo_path.join(name))
    end

    def assert_status(status)
        assert_equal(status, @cmd.status)
    end

    def assert_stdout(message)
        assert_output(@stdout, message)
    end

    def assert_stderr(message)
        assert_output(@stderr, message)
    end

    def assert_output(stream, message)
        stream.rewind
        assert_equal(message, stream.read)
    end

    def mkdir(name)
        FileUtils.mkdir_p(repo_path.join(name))
    end
end