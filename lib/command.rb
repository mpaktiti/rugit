require_relative "./command/add"
require_relative "./command/commit"
require_relative "./command/init"

module Command
    Unknown = Class.new(StandardError)

    COMMANDS = {
        "init" => Init,
        "add" => Add,
        "commit" => Commit
    }

    def self.execute(dir, env, argv, stdin, stdout, stderr)
        name = argv.first
        args = argv.drop(1)

        unless COMMANDS.has_key?(name)
            raise Unknown, "'#{ name }' is not a rugit command."
        end

        command_class = COMMANDS[name]
        command = command_class.new(dir, env, args, stdin, stdout, stderr)

        command.execute
        command
    end
end