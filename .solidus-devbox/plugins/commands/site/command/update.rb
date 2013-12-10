require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Update < SiteCommand
        def description(opts)
          opts.separator "Update the site to reflect the latest Solidus site template."
          opts.separator "See https://github.com/solidusjs/solidus-site-template for more information."
        end

        def options(opts)
          site_template_command_line_options(opts)
        end

        def execute
          super do
            confirm_command

            unless @site_template_host_path
              @env.ui.info("Cloning site template...")
              clone_site_template(@site_template_git_url)
              @site_template_host_path = SITE_TEMPLATE_HOST_PATH
            end

            @env.ui.info("Updating site from template...")
            update_gruntfile
            update_package_dependencies

            @env.ui.success("#{@site_name} is updated, please review the modified files")
          end

          # Success, exit status 0
          0
        end

        protected

        def confirm_command
          @env.ui.warn("Warning! The following files will be modified:")
          @env.ui.info("  #{@site_name}/Gruntfile.js")
          @env.ui.info("  #{@site_name}/package.json")
          abort unless @env.ui.ask("Are you sure you want to update #{@site_name}? [y/n] ") == 'y'
        end

        def update_gruntfile
          template_file_path = File.join(@site_template_host_path, 'root/Gruntfile.js')
          site_file_path     = File.join(@site_host_path, 'Gruntfile.js')

          FileUtils.copy(template_file_path, site_file_path)
        end

        def update_package_dependencies
          template_file_path = File.join(@site_template_host_path, 'root/package.json')
          site_file_path     = File.join(@site_host_path, 'package.json')

          template_package = JSON.load(File.new(template_file_path))
          site_package     = JSON.load(File.new(site_file_path))
          site_package['devDependencies'].merge!(template_package['devDependencies'])
          site_package['dependencies'].merge!(template_package['dependencies'])

          File.open(site_file_path, 'w') do |file|
            file.write(JSON.pretty_generate(site_package))
          end
        end
      end
    end
  end
end
