require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Create < SiteCommand
        def parse_arguments
          extra_argv = parse_argv([1]) do |opts|
            opts.banner << " <site>"
            opts.separator "Create a new Solidus site, based on a Solidus site template."
            opts.separator "See https://github.com/solidusjs/solidus-site-template for more information."
            opts.separator ""
            site_template_command_line_options(opts)
          end

          @site_name = extra_argv[0]

          load_site
          fail("Directory already exists and is not empty: #{@site_host_path}") if directory_exists?(@site_host_path)
        end

        def execute
          with_running_vm do
            unless @site_template_guest_path
              @env.ui.info("Cloning site template...")
              clone_site_template(@site_template_git_url)
            end

            @env.ui.info("Creating site from template...")
            create_site_from_template(@site_template_guest_path)

            @env.ui.success("#{@site_name} is created, ready to be started")
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
