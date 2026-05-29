#!/usr/bin/env ruby
# Adds BloomWidget extension + App Group to the Flutter iOS Xcode project.
# Usage: cd ios && gem install xcodeproj && ruby configure_widget.rb

require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

if project.targets.any? { |t| t.name == 'BloomWidgetExtension' }
  puts 'BloomWidgetExtension target already exists — skipping.'
  exit 0
end

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
end

widget_target = project.new_target(
  :app_extension,
  'BloomWidgetExtension',
  :ios,
  '17.0'
)
widget_target.product_type = 'com.apple.product-type.app-extension'

widget_group = project.main_group.new_group('BloomWidget', 'BloomWidget')
shared_group = project.main_group.new_group('Shared', 'Shared')

widget_sources = %w[
  BloomWidget/BloomWidget.swift
  BloomWidget/BloomWidgetProvider.swift
  BloomWidget/BloomWidgetViews.swift
  BloomWidget/BloomWidgetIntents.swift
  Shared/WidgetDataStore.swift
]

runner_sources = %w[
  Runner/WidgetBridgePlugin.swift
  Shared/WidgetDataStore.swift
]

def add_source(project, target, group, path)
  folder = File.dirname(path)
  base = File.basename(path)
  ref = if folder == '.' || folder.empty?
          group.new_file(base)
        else
          group.new_reference(File.join(__dir__, path))
        end
  target.source_build_phase.add_file_reference(ref)
end

runner_group = project.main_group['Runner'] || project.main_group.new_group('Runner', 'Runner')

widget_sources.each { |p| add_source(project, widget_target, widget_group, p) }
runner_sources.each do |p|
  next if runner.source_build_phase.files_references.any? { |r| r.path&.include?(File.basename(p)) }
  group = p.start_with?('Runner/') ? runner_group : shared_group
  add_source(project, runner, group, p)
end

widget_target.build_configurations.each do |config|
  config.build_settings.merge!(
    'INFOPLIST_FILE' => 'BloomWidget/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'BloomWidget/BloomWidget.entitlements',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.dailyhealth.dailyHealth.BloomWidget',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
    'SKIP_INSTALL' => 'YES',
    'CURRENT_PROJECT_VERSION' => '$(FLUTTER_BUILD_NUMBER)',
    'MARKETING_VERSION' => '$(FLUTTER_BUILD_NAME)',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  )
end

embed_phase = runner.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name = 'Embed App Extensions'
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << embed_phase
end

product_ref = widget_target.product_reference
build_file = embed_phase.add_file_reference(product_ref)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

runner.add_dependency(widget_target)

# Embed must run before Flutter's "Thin Binary" script or Xcode reports a cycle.
thin = runner.shell_script_build_phases.find { |p| p.name == 'Thin Binary' }
if thin && embed_phase
  runner.build_phases.delete(embed_phase)
  runner.build_phases.insert(runner.build_phases.index(thin), embed_phase)
end

project.save
puts 'Done. Open ios/Runner.xcworkspace and enable App Group for Runner + BloomWidgetExtension in Signing.'
