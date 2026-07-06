#!/bin/bash
# 便捷调用脚本
set -e
cd "$(dirname "$0")/.."
gem install xcodeproj --no-document 2>/dev/null
ruby Scripts/create_xcodeproj.rb
