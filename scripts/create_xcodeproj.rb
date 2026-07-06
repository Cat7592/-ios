#!/usr/bin/env ruby
# frozen_string_literal: true
#
# 生成 Xcode 项目 + xcscheme（用于无签名 IPA 构建）
# 用法: ruby scripts/create_xcodeproj.rb
#

require 'xcodeproj'
require 'fileutils'
require 'pathname'

PROJECT_NAME   = 'maolaoda-parser'
BUNDLE_ID      = 'com.maolaoda.parser'
DEPLOY_TARGET  = '16.0'
SWIFT_VERSION  = '5.0'

BASE_DIR       = File.expand_path('..', __dir__)
PROJECT_PATH   = File.join(BASE_DIR, "#{PROJECT_NAME}.xcodeproj")
SCHEME_DIR     = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes')
SCHEME_PATH    = File.join(SCHEME_DIR, "#{PROJECT_NAME}.xcscheme")

# ── 收集所有 .swift 文件（按目录） ──
swift_files = []
%w[App Models Services ViewModels Views].each do |sub|
  dir = File.join(BASE_DIR, sub)
  next unless File.directory?(dir)
  Dir.glob(File.join(dir, '**', '*.swift')).each do |f|
    rel = Pathname.new(f).relative_path_from(BASE_DIR).to_s
    swift_files << { rel: rel, abs: f, group: sub }
  end
end

abort '❌ 未找到 Swift 源文件!' if swift_files.empty?
puts "📦 #{swift_files.count} 个 Swift 源文件"

# ── 清理旧项目 ──
FileUtils.rm_rf(PROJECT_PATH)

# ── 创建 project ──
project = Xcodeproj::Project.new(PROJECT_PATH)
main_group = project.main_group

# ── 创建 target ──
target = project.new_target(:application, PROJECT_NAME, :ios)
target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME']                  = '猫老大解析助手'
  s['PRODUCT_BUNDLE_IDENTIFIER']     = BUNDLE_ID
  s['CODE_SIGN_IDENTITY']            = ''
  s['CODE_SIGNING_REQUIRED']         = 'NO'
  s['CODE_SIGNING_ALLOWED']          = 'NO'
  s['INFOPLIST_FILE']                = 'App/Info.plist'
  s['SWIFT_VERSION']                 = SWIFT_VERSION
  s['IPHONEOS_DEPLOYMENT_TARGET']    = DEPLOY_TARGET
  s['TARGETED_DEVICE_FAMILY']        = '1'
  s['ENABLE_BITCODE']                = 'NO'
  s['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  s['SWIFT_COMPILATION_MODE']        = 'singlefile'
end

# ── 按目录创建 group 并添加源文件 ──
groups = {}
swift_files.each do |f|
  groups[f[:group]] ||= main_group.new_group(f[:group], f[:group])
  ref = groups[f[:group]].new_file(f[:abs])
  target.source_build_phase.add_file_reference(ref)
end

# ── Info.plist ──
plist_abs = File.join(BASE_DIR, 'App', 'Info.plist')
if File.exist?(plist_abs)
  plist_ref = main_group.new_file(plist_abs)
  # 不放入 build phase — INFOPLIST_FILE 已指定路径
end

# ── 保存 project ──
project.save
puts "✅ #{PROJECT_PATH}"

# ── 生成 xcscheme ──
FileUtils.mkdir_p(SCHEME_DIR)

scheme_uuid = target.uuid
File.write(SCHEME_PATH, <<~XML)
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1540" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{scheme_uuid}"
               BuildableName = "#{PROJECT_NAME}.app"
               BlueprintName = "#{PROJECT_NAME}"
               ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Release">
      <Testables/>
   </TestAction>
   <LaunchAction buildConfiguration = "Release">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{scheme_uuid}"
            BuildableName = "#{PROJECT_NAME}.app"
            BlueprintName = "#{PROJECT_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{scheme_uuid}"
            BuildableName = "#{PROJECT_NAME}.app"
            BlueprintName = "#{PROJECT_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Release"/>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"/>
</Scheme>
XML

puts "✅ #{SCHEME_PATH}"
puts "🎉 完成 — Target UUID: #{scheme_uuid}"
