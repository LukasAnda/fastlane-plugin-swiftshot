require 'fastlane_core/ui/ui'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class SwiftshotHelper
      INSTALL_HINT = "Install it with `brew install lukasanda/tap/swiftshot` (macOS) or " \
                     "`curl -fsSL https://raw.githubusercontent.com/LukasAnda/swiftshot/main/install.sh | sh` (macOS, Linux), " \
                     "or set binary_path."

      # The swiftshot executable: binary_path, then `swiftshot` on PATH, then ~/.swiftshot/bin/swiftshot.
      def self.find_binary(binary_path = nil, path: ENV.fetch('PATH', ''), home: Dir.home)
        if binary_path
          expanded = File.expand_path(binary_path)
          UI.user_error!("swiftshot not found at #{binary_path}. #{INSTALL_HINT}") unless executable?(expanded)
          return expanded
        end

        path.split(File::PATH_SEPARATOR).each do |dir|
          candidate = File.join(dir, 'swiftshot')
          return candidate if executable?(candidate)
        end

        fallback = File.join(home, '.swiftshot', 'bin', 'swiftshot')
        return fallback if executable?(fallback)

        UI.user_error!("swiftshot not found. #{INSTALL_HINT}")
      end

      def self.executable?(file)
        File.file?(file) && File.executable?(file)
      end

      # Arguments for `swiftshot` and the folder the screenshots go to. Runs in the project folder.
      def self.plan(params, lane_platform: nil)
        config_path = params[:config] || (File.exist?('swiftshot.json') ? 'swiftshot.json' : nil)
        config = read_config(config_path)
        android = android?(params[:platform], lane_platform)

        args = ['run']
        args += value_flag('--config', params[:config])
        args += value_flag('--platform', params[:platform])
        args += list_flag('--devices', params[:devices])
        args += list_flag('--languages', params[:languages])
        args += list_flag('--ios', params[:ios_versions])
        args += list_flag('--appearances', appearances(params[:appearances], params[:dark_mode]))
        args += list_flag('--previews', params[:previews])

        output, output_args = output_directory(params, config, config_path, android)
        args += output_args
        args << '--clear' if params[:clear_previous_screenshots]
        args += value_flag('--frame', params[:frame])
        args += value_flag('--layout', params[:layout])
        args += Array(params[:extra_args]).map(&:to_s)

        { args: args, output_directory: File.expand_path(output) }
      end

      # The screenshots folder and the flags for it. swiftshot.json's own output_directory is
      # left to swiftshot, which resolves it next to the config file.
      def self.output_directory(params, config, config_path, android)
        return [params[:output_directory], ['--output', params[:output_directory]]] if params[:output_directory]
        return [File.expand_path(config['output_directory'], File.dirname(config_path)), []] if config['output_directory']

        output = default_output_directory(android)
        args = ['--output', output]
        args += ['--layout', 'fastlane'] if android && params[:layout].nil? && config['layout'].nil?
        [output, args]
      end

      # Where snapshot (iOS) and supply (Android) look by default.
      def self.default_output_directory(android)
        fastlane = File.directory?('fastlane')
        if android
          fastlane ? 'fastlane/metadata/android' : 'metadata'
        else
          fastlane ? 'fastlane/screenshots' : 'screenshots'
        end
      end

      def self.android?(platform, lane_platform)
        return platform == 'android' if platform

        lane_platform.to_s == 'android'
      end

      # snapshot's dark_mode: true renders dark, false light.
      def self.appearances(appearances, dark_mode)
        return appearances if appearances
        return nil if dark_mode.nil?

        dark_mode ? ['dark'] : ['light']
      end

      def self.value_flag(flag, value)
        value.nil? ? [] : [flag, value.to_s]
      end

      def self.list_flag(flag, values)
        values = Array(values).map(&:to_s).reject(&:empty?)
        values.empty? ? [] : [flag, values.join(',')]
      end

      def self.read_config(path)
        return {} unless path && File.exist?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError => e
        UI.user_error!("Could not read #{path}: #{e.message}")
      end

      # Screenshot count and errors from swiftshot-report.json, nil when there is none.
      def self.read_report(output_directory)
        file = File.join(output_directory, 'swiftshot-report.json')
        return nil unless File.exist?(file)

        report = JSON.parse(File.read(file))
        { screenshots: Array(report['screenshots']).size, errors: Array(report['errors']) }
      rescue JSON::ParserError
        nil
      end

      # The line that says what went wrong: the last one mentioning an error, else the last line.
      def self.last_error_line(output)
        lines = output.to_s.gsub(/\e\[[0-9;]*m/, '').lines.map(&:strip).reject(&:empty?)
        lines.reverse.find { |line| line =~ /\berror\b|failed/i } || lines.last
      end
    end
  end
end
