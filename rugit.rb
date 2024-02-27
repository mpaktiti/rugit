#! /usr/bin/env ruby

require "fileutils"
require "pathname"

require_relative "./author"
require_relative "./commit"
require_relative "./database"
require_relative "./entry"
require_relative "./refs"
require_relative "./tree"
require_relative "./workspace"

# get the first item from the command line arguments
command = ARGV.shift

case command
when "init"
    # get the input directory, if null use current (Dir.getwd)
    path = ARGV.fetch(0, Dir.getwd)

    # convert relative path to absolute
    root_path = Pathname.new(File.expand_path(path))

    git_path = root_path.join(".git")

    ["objects", "refs"].each do |dir|
        begin
            # create dir including any parent dir that doesn't exist (like mkdir -p)
            FileUtils.mkdir_p(git_path.join(dir))
        rescue Errno::EACCES => error
            $stderr.puts "fatal: #{ error.message }"
            exit 1
        end
    end

    puts "Initialized empty Rugit repository in #{ git_path }"
    exit 0
when "commit"
    root_path = Pathname.new(Dir.getwd)
    git_path = root_path.join(".git")
    db_path = git_path.join("objects")

    workspace = Workspace.new(root_path)
    database = Database.new(db_path)
    refs = Refs.new(git_path)

    entries = workspace.list_files.map do |path|
        data = workspace.read_file(path)
        blob = Blob.new(data)

        database.store(blob)

        stat = workspace.stat_file(path)
        Entry.new(path, blob.oid, stat)
    end

    tree = Tree.new(entries)
    database.store(tree)
    # puts "tree: #{ tree.oid }"

    parent = refs.read_head
    name = ENV.fetch("GIT_AUTHOR_NAME")
    email = ENV.fetch("GIT_AUTHOR_EMAIL")
    author = Author.new(name, email, Time.now)
    message = $stdin.read

    commit = Commit.new(parent, tree.oid, author, message)
    database.store(commit)
    refs.update_head(commit.oid)
    # File.open(.join("HEAD"), File::WRONLY | File::CREAT) do |file|
    #     file.puts(commit.oid)
    # end

    is_root = parent.nil? ? "(root-commit) " : ""
    puts "[#{ is_root}#{ commit.oid }] #{ message.lines.first }"
    exit 0
else
    $stderr.puts "rugit: '#{ command }' is not a rugit command."
    exit 1
end