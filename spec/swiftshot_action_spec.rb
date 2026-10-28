require 'tmpdir'

describe Fastlane::Actions::SwiftshotAction do
  let(:binary) { '/usr/local/bin/swiftshot' }

  def status(code)
    double('status', exitstatus: code)
  end

  def run_lane(body)
    Fastlane::FastFile.new.parse("lane :test do\n#{body}\nend").runner.execute(:test)
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = File.realpath(dir)
      Dir.chdir(@dir) { example.run }
    end
  end

  before do
    Fastlane::Actions.lane_context.clear
    allow(Fastlane::Helper::SwiftshotHelper).to receive(:find_binary).and_return(binary)
  end

  it 'runs swiftshot with the options and returns the output folder' do
    expect(Fastlane::Actions).to receive(:sh)
      .with(binary, 'run', '--devices', 'iPhone 17 Pro Max', '--languages', 'en-US', '--output', 'shots')
      .and_yield(status(0), '', '')

    result = run_lane('swiftshot(devices: ["iPhone 17 Pro Max"], languages: ["en-US"], output_directory: "shots")')

    expect(result).to eq(File.join(@dir, 'shots'))
    expect(Fastlane::Actions.lane_context[:SWIFTSHOT_OUTPUT_DIRECTORY]).to eq(File.join(@dir, 'shots'))
    expect(Fastlane::Actions.lane_context[:SNAPSHOT_SCREENSHOTS_PATH]).to eq(File.join(@dir, 'shots'))
  end

  it 'reads the screenshot count from swiftshot-report.json' do
    FileUtils.mkdir_p('screenshots')
    File.write('screenshots/swiftshot-report.json', '{"screenshots": [{}, {}, {}], "errors": []}')
    allow(Fastlane::Actions).to receive(:sh).and_yield(status(0), '', '')

    run_lane('swiftshot')

    expect(Fastlane::Actions.lane_context[:SWIFTSHOT_SCREENSHOT_COUNT]).to eq(3)
  end

  it 'fails the lane with the last error line' do
    output = "Rendering\nerror: Welcome · iPhone 17 Pro Max · en-US: timed out\n1 of 2 screenshots failed\n"
    allow(Fastlane::Actions).to receive(:sh).and_yield(status(1), output, '')

    expect { run_lane('swiftshot') }.to raise_error(FastlaneCore::Interface::FastlaneError, 'swiftshot failed (exit 1): 1 of 2 screenshots failed')
  end

  it 'runs in project_path' do
    FileUtils.mkdir_p('app/fastlane')
    expect(Fastlane::Actions).to receive(:sh) do |*args, &block|
      expect(Dir.pwd).to eq(File.join(@dir, 'app'))
      expect(args).to eq([binary, 'run', '--output', 'fastlane/screenshots'])
      block.call(status(0), '', '')
    end

    expect(run_lane('swiftshot(project_path: "app")')).to eq(File.join(@dir, 'app/fastlane/screenshots'))
  end

  it 'sets the screengrab path for Android' do
    allow(Fastlane::Actions).to receive(:sh).and_yield(status(0), '', '')

    run_lane('swiftshot(platform: "android")')

    expect(Fastlane::Actions.lane_context[:SCREENGRAB_OUTPUT_DIRECTORY]).to eq(File.join(@dir, 'metadata'))
    expect(Fastlane::Actions.lane_context[:SNAPSHOT_SCREENSHOTS_PATH]).to be_nil
  end

  it 'has a capture_preview_screenshots alias' do
    expect(Fastlane::Actions).to receive(:sh).with(binary, 'run', '--output', 'screenshots').and_yield(status(0), '', '')

    run_lane('capture_preview_screenshots')
  end
end
