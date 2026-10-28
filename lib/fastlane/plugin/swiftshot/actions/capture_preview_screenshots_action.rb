require 'fastlane/action'
require_relative 'swiftshot_action'

module Fastlane
  module Actions
    class CapturePreviewScreenshotsAction < SwiftshotAction
      def self.description
        "Alias for the `swiftshot` action"
      end
    end
  end
end
