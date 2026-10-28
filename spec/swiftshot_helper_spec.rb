require 'tmpdir'

describe Fastlane::Helper::SwiftshotHelper do
  let(:helper) { Fastlane::Helper::SwiftshotHelper }

  def params(values = {})
    FastlaneCore::Configuration.create(Fastlane::Actions::SwiftshotAction.available_options, values)
  end

  def in_tmp
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { yield(dir) }
    end
  end

  def make_executable(path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "#!/bin/sh\n")
    File.chmod(0o755, path)
    path
  end

  describe '.find_binary' do
    it 'uses binary_path when it is executable' do
      in_tmp do |dir|
        bin = make_executable(File.join(dir, 'custom', 'swiftshot'))
        expect(helper.find_binary(bin, path: '', home: dir)).to eq(bin)
      end
    end

    it 'fails when binary_path is missing' do
      expect { helper.find_binary('/nope/swiftshot', path: '', home: '/nope') }.to raise_error(FastlaneCore::Interface::FastlaneError, %r{not found at /nope/swiftshot})
    end

    it 'finds swiftshot on PATH first' do
      in_tmp do |dir|
        on_path = make_executable(File.join(dir, 'bin', 'swiftshot'))
        make_executable(File.join(dir, '.swiftshot', 'bin', 'swiftshot'))
        expect(helper.find_binary(nil, path: "#{dir}/empty:#{dir}/bin", home: dir)).to eq(on_path)
      end
    end

    it 'falls back to ~/.swiftshot/bin/swiftshot' do
      in_tmp do |dir|
        installed = make_executable(File.join(dir, '.swiftshot', 'bin', 'swiftshot'))
        expect(helper.find_binary(nil, path: "#{dir}/bin", home: dir)).to eq(installed)
      end
    end

    it 'ignores files that are not executable' do
      in_tmp do |dir|
        FileUtils.mkdir_p(File.join(dir, 'bin'))
        File.write(File.join(dir, 'bin', 'swiftshot'), '')
        expect { helper.find_binary(nil, path: "#{dir}/bin", home: dir) }.to raise_error(FastlaneCore::Interface::FastlaneError, /brew install lukasanda/)
      end
    end
  end

  describe '.plan' do
    it 'defaults to fastlane/screenshots in a fastlane project, like snapshot' do
      in_tmp do |dir|
        FileUtils.mkdir_p('fastlane')
        plan = helper.plan(params)
        expect(plan[:args]).to eq(['run', '--output', 'fastlane/screenshots'])
        expect(plan[:output_directory]).to eq(File.join(File.realpath(dir), 'fastlane/screenshots'))
      end
    end

    it 'defaults to screenshots without a fastlane folder' do
      in_tmp do
        expect(helper.plan(params)[:args]).to eq(['run', '--output', 'screenshots'])
      end
    end

    it 'maps every option to its flag' do
      in_tmp do
        plan = helper.plan(params(
                             config: 'shots.json',
                             platform: 'ios',
                             devices: ['iPhone 17 Pro Max', 'iPad Pro 13-inch (M5)'],
                             languages: ['en-US', 'de-DE'],
                             ios_versions: ['26.5', '27.1'],
                             appearances: ['light', 'dark'],
                             previews: ['Welcome', 'Stats*'],
                             output_directory: 'out',
                             clear_previous_screenshots: true,
                             frame: 'appstore',
                             extra_args: ['--accept-bezel-license']
                           ))
        expect(plan[:args]).to eq([
                                    'run', '--config', 'shots.json', '--platform', 'ios',
                                    '--devices', 'iPhone 17 Pro Max,iPad Pro 13-inch (M5)',
                                    '--languages', 'en-US,de-DE', '--ios', '26.5,27.1',
                                    '--appearances', 'light,dark', '--previews', 'Welcome,Stats*',
                                    '--output', 'out', '--clear', '--frame', 'appstore', '--accept-bezel-license'
                                  ])
      end
    end

    it 'takes comma separated strings, as from env vars' do
      in_tmp do
        plan = helper.plan(params(devices: 'iPhone 17 Pro Max,iPad Pro 13-inch (M5)', languages: 'en-US'))
        expect(plan[:args]).to include('--devices', 'iPhone 17 Pro Max,iPad Pro 13-inch (M5)', '--languages', 'en-US')
      end
    end

    it 'maps dark_mode like snapshot' do
      in_tmp do
        expect(helper.plan(params(dark_mode: true))[:args]).to include('--appearances', 'dark')
        expect(helper.plan(params(dark_mode: false))[:args]).to include('--appearances', 'light')
        expect(helper.plan(params(dark_mode: true, appearances: ['light', 'dark']))[:args]).to include('--appearances', 'light,dark')
        expect(helper.plan(params)[:args]).not_to include('--appearances')
      end
    end

    it 'leaves output_directory to swiftshot.json when it sets one' do
      in_tmp do |dir|
        File.write('swiftshot.json', '{"scheme": "App", "output_directory": "shots"}')
        plan = helper.plan(params)
        expect(plan[:args]).to eq(['run'])
        expect(plan[:output_directory]).to eq(File.join(File.realpath(dir), 'shots'))
      end
    end

    it 'resolves the output of a --config file next to it' do
      in_tmp do |dir|
        FileUtils.mkdir_p('config')
        File.write('config/ss.json', '{"output_directory": "out"}')
        plan = helper.plan(params(config: 'config/ss.json'))
        expect(plan[:args]).to eq(['run', '--config', 'config/ss.json'])
        expect(plan[:output_directory]).to eq(File.join(File.realpath(dir), 'config/out'))
      end
    end

    it 'lets output_directory win over swiftshot.json' do
      in_tmp do
        File.write('swiftshot.json', '{"output_directory": "shots"}')
        expect(helper.plan(params(output_directory: 'other'))[:args]).to eq(['run', '--output', 'other'])
      end
    end

    it 'defaults Android to the supply folders, like screengrab' do
      in_tmp do
        FileUtils.mkdir_p('fastlane')
        expect(helper.plan(params(platform: 'android'))[:args]).to eq(['run', '--platform', 'android', '--output', 'fastlane/metadata/android', '--layout', 'fastlane'])
        expect(helper.plan(params, lane_platform: :android)[:args]).to eq(['run', '--output', 'fastlane/metadata/android', '--layout', 'fastlane'])
        expect(helper.plan(params(layout: 'swiftshot'), lane_platform: :android)[:args]).to eq(['run', '--output', 'fastlane/metadata/android', '--layout', 'swiftshot'])
      end
    end

    it 'keeps the layout from swiftshot.json on Android' do
      in_tmp do
        File.write('swiftshot.json', '{"layout": "swiftshot"}')
        expect(helper.plan(params(platform: 'android'))[:args]).to eq(['run', '--platform', 'android', '--output', 'metadata'])
      end
    end

    it 'fails on a broken swiftshot.json' do
      in_tmp do
        File.write('swiftshot.json', '{')
        expect { helper.plan(params) }.to raise_error(FastlaneCore::Interface::FastlaneError, /Could not read swiftshot.json/)
      end
    end
  end

  describe 'options' do
    it 'rejects unknown values' do
      expect { params(platform: 'web') }.to raise_error(FastlaneCore::Interface::FastlaneError, /platform must be ios or android/)
      expect { params(appearances: ['sepia']) }.to raise_error(FastlaneCore::Interface::FastlaneError, /Unknown appearance sepia/)
      expect { params(frame: 'fancy') }.to raise_error(FastlaneCore::Interface::FastlaneError, /frame must be/)
      expect { params(layout: 'play') }.to raise_error(FastlaneCore::Interface::FastlaneError, /layout must be/)
    end
  end

  describe '.read_report' do
    it 'counts the screenshots' do
      in_tmp do |dir|
        File.write('swiftshot-report.json', JSON.generate(screenshots: [{ file: 'a.png' }, { file: 'b.png' }], errors: []))
        expect(helper.read_report(dir)).to eq(screenshots: 2, errors: [])
      end
    end

    it 'returns nil without a report' do
      in_tmp { |dir| expect(helper.read_report(dir)).to be_nil }
    end
  end

  describe '.last_error_line' do
    it 'picks the last error and strips colours' do
      output = "Building\n\e[31merror:\e[0m Welcome · iPhone 17 Pro Max · en-US: timed out\nDone in 3 s\n"
      expect(helper.last_error_line(output)).to eq('error: Welcome · iPhone 17 Pro Max · en-US: timed out')
    end

    it 'falls back to the last line' do
      expect(helper.last_error_line("one\ntwo\n\n")).to eq('two')
    end
  end
end
