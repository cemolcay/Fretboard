# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Fretboard iOS' do
  use_frameworks!
  pod 'MusicTheorySwift'
  pod 'CenterTextLayer'
end

target 'Fretboard Mac' do
  use_frameworks!
  pod 'MusicTheorySwift'
  pod 'CenterTextLayer'
end

target 'Fretboard TV' do
  use_frameworks!
  pod 'MusicTheorySwift'
  pod 'CenterTextLayer'
end

target 'Example iOS' do
  use_frameworks!
  pod 'Fretboard', :path => '.'
end

target 'Example Mac' do
  use_frameworks!
  pod 'Fretboard', :path => '.'
end

target 'Example TV' do
  use_frameworks!
  pod 'Fretboard', :path => '.'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(FRAMEWORK_SEARCH_PATHS)']
  end
end
