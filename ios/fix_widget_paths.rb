#!/usr/bin/env ruby
# Fixes Xcode file references for BloomWidget + Shared folders.
# Usage: cd ios && ruby fix_widget_paths.rb

require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

shared_group = project.main_group['Shared']
bloom_group = project.main_group['BloomWidget']
runner_group = project.main_group['Runner']

store_refs = project.files.select { |f| f.path == 'WidgetDataStore.swift' }
canonical = store_refs.first

if canonical && store_refs.size > 1
  widget_target = project.targets.find { |t| t.name == 'BloomWidgetExtension' }
  runner_target = project.targets.find { |t| t.name == 'Runner' }

  store_refs[1..].each do |dup|
    widget_target.source_build_phase.files.each do |bf|
      bf.remove_from_project if bf.file_ref == dup
    end
    runner_target.source_build_phase.files.each do |bf|
      bf.remove_from_project if bf.file_ref == dup
    end
    bloom_group&.children&.delete(dup)
    dup.remove_from_project
  end
end

if bloom_group && canonical
  bloom_group.children.delete(canonical) if bloom_group.children.include?(canonical)
  wrong_in_bloom = bloom_group.children.select { |c| c.path == 'WidgetDataStore.swift' }
  wrong_in_bloom.each { |c| bloom_group.children.delete(c) }

  unless shared_group.files.include?(canonical)
    shared_group.files << canonical
  end

  unless widget_target.source_build_phase.files_references.include?(canonical)
    widget_target.source_build_phase.add_file_reference(canonical)
  end
end

if runner_group
  plugin = project.files.find { |f| f.path == 'WidgetBridgePlugin.swift' }
  if plugin && shared_group&.files&.include?(plugin)
    shared_group.files.delete(plugin)
    runner_group.files << plugin unless runner_group.files.include?(plugin)
  end
end

project.save
puts 'Fixed Bloom widget file paths.'
