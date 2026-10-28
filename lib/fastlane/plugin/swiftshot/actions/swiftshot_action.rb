require 'fastlane/action'
require 'fastlane/boolean'
require 'fastlane_core/configuration/config_item'
require_relative '../helper/swiftshot_helper'

module Fastlane
  module Actions
    module SharedValues
      SWIFTSHOT_OUTPUT_DIRECTORY = :SWIFTSHOT_OUTPUT_DIRECTORY
      SWIFTSHOT_SCREENSHOT_COUNT = :SWIFTSHOT_SCREENSHOT_COUNT
    end

    class SwiftshotAction < Action
      def self.run(params)
        helper = Helper::SwiftshotHelper
        binary = helper.find_binary(params[:binary_path])
        project_path = File.expand_path(params[:project_path] || '.')
        UI.user_error!("project_path #{project_path} does not exist") unless File.directory?(project_path)

        Dir.chdir(project_path) do
          plan = helper.plan(params, lane_platform: Actions.lane_context[SharedValues::PLATFORM_NAME])
          output_directory = plan[:output_directory]

          Actions.sh(binary, *plan[:args]) do |status, output, _command|
            next if status.nil? || status.exitstatus.to_i.zero?

            UI.user_error!("swiftshot failed (exit #{status.exitstatus}): #{helper.last_error_line(output)}")
          end

          Actions.lane_context[SharedValues::SWIFTSHOT_OUTPUT_DIRECTORY] = output_directory
          # What deliver, frameit (iOS) and supply users read after snapshot and screengrab.
          if helper.android?(params[:platform], Actions.lane_context[SharedValues::PLATFORM_NAME])
            Actions.lane_context[:SCREENGRAB_OUTPUT_DIRECTORY] = output_directory
          else
            Actions.lane_context[:SNAPSHOT_SCREENSHOTS_PATH] = output_directory
          end

          report = helper.read_report(output_directory)
          if report
            Actions.lane_context[SharedValues::SWIFTSHOT_SCREENSHOT_COUNT] = report[:screenshots]
            UI.success("#{report[:screenshots]} screenshots in #{output_directory}")
          end

          output_directory
        end
      end

      def self.description
        "Screenshots from SwiftUI, Compose and Flutter previews with Swiftshot"
      end

      def self.details
        "Runs `swiftshot run`. Reads swiftshot.json if there is one; options set here win. " \
          "Screenshots go where deliver and supply look, like snapshot and screengrab."
      end

      def self.authors
        ["Lukas Anda"]
      end

      def self.output
        [
          ['SWIFTSHOT_OUTPUT_DIRECTORY', 'Absolute path of the screenshots folder'],
          ['SWIFTSHOT_SCREENSHOT_COUNT', 'Number of screenshots, from swiftshot-report.json'],
          ['SNAPSHOT_SCREENSHOTS_PATH', 'Same folder, set for iOS so deliver and frameit find it'],
          ['SCREENGRAB_OUTPUT_DIRECTORY', 'Same folder, set for Android']
        ]
      end

      def self.return_type
        :string
      end

      def self.return_value
        "Absolute path of the screenshots folder"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :binary_path,
                                       env_name: 'SWIFTSHOT_BINARY_PATH',
                                       description: 'Path to the swiftshot binary (default: swiftshot on PATH, then ~/.swiftshot/bin/swiftshot)',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :config,
                                       env_name: 'SWIFTSHOT_CONFIG',
                                       description: 'Path to swiftshot.json (default: ./swiftshot.json if present)',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :project_path,
                                       env_name: 'SWIFTSHOT_PROJECT_PATH',
                                       description: 'Folder to run swiftshot in (default: the project root)',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :platform,
                                       env_name: 'SWIFTSHOT_PLATFORM',
                                       description: 'ios or android (default: detected by swiftshot)',
                                       optional: true,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("platform must be ios or android, not #{value}") unless %w(ios android).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :devices,
                                       env_name: 'SWIFTSHOT_DEVICES',
                                       description: 'Devices to render, e.g. ["iPhone 17 Pro Max", "Pixel 10 Pro"]',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :languages,
                                       env_name: 'SWIFTSHOT_LANGUAGES',
                                       description: 'Languages, e.g. ["en-US", "de-DE"]',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :ios_versions,
                                       env_name: 'SWIFTSHOT_IOS_VERSIONS',
                                       description: 'iOS runtime versions (default: newest installed)',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :appearances,
                                       env_name: 'SWIFTSHOT_APPEARANCES',
                                       description: 'light, dark or both',
                                       optional: true,
                                       type: Array,
                                       verify_block: proc do |value|
                                         bad = Array(value) - %w(light dark)
                                         UI.user_error!("Unknown appearance #{bad.join(', ')}") unless bad.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :dark_mode,
                                       env_name: 'SWIFTSHOT_DARK_MODE',
                                       description: "As in snapshot: true renders dark, false light. appearances wins",
                                       optional: true,
                                       type: Fastlane::Boolean),
          FastlaneCore::ConfigItem.new(key: :previews,
                                       env_name: 'SWIFTSHOT_PREVIEWS',
                                       description: 'Only these previews, names or * globs',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :output_directory,
                                       env_name: 'SWIFTSHOT_OUTPUT_DIRECTORY',
                                       description: 'Where screenshots go (default: swiftshot.json, else fastlane/screenshots, Android fastlane/metadata/android)',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :clear_previous_screenshots,
                                       env_name: 'SWIFTSHOT_CLEAR_PREVIOUS_SCREENSHOTS',
                                       description: 'Delete previous screenshots first',
                                       optional: true,
                                       type: Fastlane::Boolean),
          FastlaneCore::ConfigItem.new(key: :frame,
                                       env_name: 'SWIFTSHOT_FRAME',
                                       description: 'Device frames: plain, appstore (iOS) or none',
                                       optional: true,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("frame must be plain, appstore or none, not #{value}") unless %w(plain appstore none).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :layout,
                                       env_name: 'SWIFTSHOT_LAYOUT',
                                       description: 'Android: swiftshot or fastlane (supply folders)',
                                       optional: true,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!("layout must be swiftshot or fastlane, not #{value}") unless %w(swiftshot fastlane).include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :extra_args,
                                       env_name: 'SWIFTSHOT_EXTRA_ARGS',
                                       description: 'More swiftshot arguments, e.g. ["--frame-color", "Deep Blue"]',
                                       optional: true,
                                       type: Array)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end

      def self.example_code
        [
          'swiftshot',
          'swiftshot(
            devices: ["iPhone 17 Pro Max", "iPad Pro 13-inch (M5)"],
            languages: ["en-US", "de-DE"],
            dark_mode: true,
            clear_previous_screenshots: true
          )',
          'swiftshot(platform: "android", devices: ["Pixel 10 Pro"])'
        ]
      end

      def self.category
        :screenshots
      end
    end
  end
end
