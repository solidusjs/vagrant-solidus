require 'optparse'

# Required dependencies
begin
  require 'listen'
rescue LoadError
  puts "The 'listen' plugin is missing: vagrant plugin install listen"
  abort
end

module VagrantPlugins
  module CommandSite
    module Command
      class Root < Vagrant.plugin("2", :command)
        def initialize(argv, env)
          super

          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

          @subcommands = Vagrant::Registry.new
          @subcommands.register(:start) do
            require File.expand_path("../start", __FILE__)
            Start
          end

          @subcommands.register(:stop) do
            require File.expand_path("../stop", __FILE__)
            Stop
          end

          @subcommands.register(:log) do
            require File.expand_path("../log", __FILE__)
            Log
          end

          @subcommands.register(:status) do
            require File.expand_path("../status", __FILE__)
            Status
          end

          @subcommands.register(:create) do
            require File.expand_path("../create", __FILE__)
            Create
          end

          @subcommands.register(:restart) do
            require File.expand_path("../restart", __FILE__)
            Restart
          end

          @subcommands.register(:update) do
            require File.expand_path("../update", __FILE__)
            Update
          end

          @subcommands.register(:watch) do
            require File.expand_path("../watch", __FILE__)
            Watch
          end
        end

        def execute
          if @main_args.include?("-h") || @main_args.include?("--help")
            # Print the help for all the site commands.
            return help
          end

          # If we reached this far then we must have a subcommand. If not,
          # then we also just print the help and exit.
          command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
          return help if !command_class || !@sub_command
          @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

          # Initialize and execute the command class
          command_class.new(@sub_args, @env).execute
        end

        # Prints the help out for this command
        def help
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant site <command> [<args>]"
            opts.separator ""
            opts.separator "Available subcommands:"

            # Add the available subcommands as separators in order to print them
            # out as well.
            keys = []
            @subcommands.each { |key, value| keys << key.to_s }

            keys.sort.each do |key|
              opts.separator "     #{key}"
            end

            opts.separator ""
            opts.separator "For help on any individual command run `vagrant site COMMAND -h`"
          end

          @env.ui.info(opts.help, :prefix => false)
        end
      end
    end
  end
end
