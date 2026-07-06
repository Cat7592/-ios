# 应用图标说明

## 图标文件要求

应用需要以下图标文件，放置在 `assets/` 目录下：

| 文件名 | 尺寸 | 用途 |
|--------|------|------|
| icon.png | 1024×1024 | 主应用图标 |
| adaptive-icon.png | 1024×1024 | Android 自适应图标 |
| splash.png | 1284×2778 | 启动画面 |
| favicon.png | 48×48 | 网页图标 |

## 图标设计方案

### 设计概念
- **主视觉**: 一只可爱的橘猫头部剪影 + 放大镜元素
- **配色方案**: 
  - 主色: #FF6B35 (橘猫橙)
  - 辅色: #FFF5F0 (浅橙背景)
  - 强调色: #333333 (深灰文字)
- **风格**: 扁平化设计，圆角处理，符合 iOS 现代设计规范

### 设计元素
1. 橘猫剪影（白色或浅色，位于图标中央）
2. 放大镜覆盖在猫脸右眼位置（代表"解析"）
3. 底部轻微阴影营造立体感
4. 圆角方形外形（iOS 风格）

## 快速生成图标

### 方法一: 使用在线工具生成
推荐使用以下工具快速生成符合规范的图标：
- https://makeappicon.com/ （上传设计稿自动生成所有尺寸）
- https://appicon.co/ （免费生成 iOS/Android 全尺寸图标）
- https://icon.kitchen/ （图标生成器）

### 方法二: 使用 ImageMagick 生成占位图标
```bash
# 安装 ImageMagick
# macOS: brew install imagemagick
# Ubuntu: sudo apt install imagemagick

# 生成 1024x1024 占位图标
convert -size 1024x1024 \
  -define gradient:angle=135 \
  radial-gradient:'#FF8C5A'-'#FF6B35' \
  -fill white -font Helvetica-Bold -pointsize 200 \
  -gravity center -annotate 0 '🐱' \
  assets/icon.png

# 生成启动画面
convert -size 1284x2778 \
  gradient:'#FFF5F0'-'#FF8C5A' \
  -fill '#FF6B35' -font Helvetica-Bold -pointsize 160 \
  -gravity center -annotate 0 '猫老大\n解析助手' \
  assets/splash.png
```

### 方法三: 使用 Python 脚本生成
```python
# 运行前安装: pip install pillow
import os
from PIL import Image, ImageDraw, ImageFont

def create_icon(size=1024):
    """生成占位图标"""
    img = Image.new('RGB', (size, size), '#FF6B35')
    draw = ImageDraw.Draw(img)
    
    # 绘制圆角矩形内框
    margin = size // 8
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 6,
        fill='#FFF5F0'
    )
    
    # 文字
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size // 3)
    except:
        font = ImageFont.load_default()
    
    draw.text(
        (size // 2, size // 2),
        '🐱',
        fill='#FF6B35',
        font=font,
        anchor='mm'
    )
    
    img.save('assets/icon.png')
    print(f'Icon created: assets/icon.png ({size}x{size})')

if __name__ == '__main__':
    os.makedirs('assets', exist_ok=True)
    create_icon(1024)
```

## 交付物
在最终交付时，确保 `assets/` 目录包含：
- `icon.png` (1024×1024) - **必须有实际图标文件**
- `adaptive-icon.png` (1024×1024)
- `splash.png` (1284×2778)
- `favicon.png` (48×48)
