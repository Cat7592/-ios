#!/usr/bin/env ruby
# frozen_string_literal: true
#
# create_xcodeproj.sh
# 生成 Xcode 项目文件 (.xcodeproj + xcscheme)
# 用法: ruby Scripts/create_xcodeproj.rb
#

require 'xcodeproj'
require 'fileutils'

PROJECT_NAME   = 'maolaoda-parser'
BUNDLE_ID      = 'com.maolaoda.parser'
DEPLOY_TARGET  = '16.0'
SWIFT_VERSION  = '5.0'
TEAM_ID        = ''  # 留空 = 无签名

BASE_DIR       = File.expand_path('..', __dir__)
PROJECT_DIR    = File.join(BASE_DIR, "#{PROJECT_NAME}.xcodeproj")

# ─────────────────────────────────────────────
# 收集所有 Swift 源文件
# ─────────────────────────────────────────────
def find_swift_files(dir)
  Dir.glob(File.join(dir, '**', '*.swift'))
     .map { |f| Pathname.new(f).relative_path_from(BASE_DIR).to_s }
end

source_files = []
%w[App Models Services ViewModels Views].each do |sub|
  d = File.join(BASE_DIR, sub)
  source_files.concat(find_swift_files(d)) if File.directory?(d)
end

abort '❌ 未找到 Swift 源文件!' if source_files.empty?

puts "📦 找到 #{source_files.count} 个 Swift 文件:"
source_files.each { |f| puts "   #{f}" }

# ─────────────────────────────────────────────
# 清理旧项目
# ─────────────────────────────────────────────
FileUtils.rm_rf(PROJECT_DIR)

# ─────────────────────────────────────────────
# 创建 project + target
# ─────────────────────────────────────────────
project = Xcodeproj::Project.new(PROJECT_DIR)

target = project.new_target(:application, PROJECT_NAME, :ios)
target.build_configurations.each do |config|
  settings = config.build_settings
  settings['CODE_SIGN_IDENTITY']          = ''
  settings['CODE_SIGNING_REQUIRED']       = 'NO'
  settings['CODE_SIGNING_ALLOWED']        = 'NO'
  settings['PRODUCT_BUNDLE_IDENTIFIER']   = BUNDLE_ID
  settings['INFOPLIST_FILE']              = 'App/Info.plist'
  settings['SWIFT_VERSION']               = SWIFT_VERSION
  settings['IPHONEOS_DEPLOYMENT_TARGET']  = DEPLOY_TARGET
  settings['TARGETED_DEVICE_FAMILY']      = '1'
  settings['PRODUCT_NAME']                = '猫老大解析助手'
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = ''
  settings['ENABLE_BITCODE']              = 'NO'
  settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited)'
  settings['OTHER_SWIFT_FLAGS']           = '$(inherited)'
end

# ─────────────────────────────────────────────
# 添加源文件到 target（按目录分组）
# ─────────────────────────────────────────────
main_group = project.main_group
main_group.clear

group_map = {}
source_files.each do |file|
  parts = file.split('/')
  group_name = parts.count > 1 ? parts[0] : 'App'
  group_map[group_name] ||= main_group.new_group(group_name, group_name)
  group_map[group_name].new_file(File.join(BASE_DIR, file))
end

# 添加文件引用到 build phase
source_files.each do |file|
  file_ref = project.files.find { |f| f.path&.end_with?(File.basename(file)) }
  next unless file_ref
  target.source_build_phase.add_file_reference(file_ref)
end

# Info.plist
plist_ref = main_group.new_file(File.join(BASE_DIR, 'App', 'Info.plist'))
target.add_resources([plist_ref])

# ─────────────────────────────────────────────
# 保存 project
# ─────────────────────────────────────────────
project.save
puts "✅ .xcodeproj 已生成: #{PROJECT_DIR}"

# ─────────────────────────────────────────────
# 创建 xcscheme (必须，xcodebuild archive 依赖)
# ─────────────────────────────────────────────
scheme_dir = File.join(PROJECT_DIR, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(scheme_dir)

scheme_path = File.join(scheme_dir, "#{PROJECT_NAME}.xcscheme")
File.write(scheme_path, <<~XCS)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{target.uuid}"
               BuildableName = "#{PROJECT_NAME}.app"
               BlueprintName = "#{PROJECT_NAME}"
               ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Release"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target.uuid}"
            BuildableName = "#{PROJECT_NAME}.app"
            BlueprintName = "#{PROJECT_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target.uuid}"
            BuildableName = "#{PROJECT_NAME}.app"
            BlueprintName = "#{PROJECT_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Release">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
XCS

puts "✅ xcscheme 已生成: #{scheme_path}"
puts ""
puts "🎉 项目生成完成!"
puts "   项目: #{PROJECT_DIR}"
puts "   Target: #{PROJECT_NAME}"
puts "   源文件: #{source_files.count}"
