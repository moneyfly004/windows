#!/bin/bash

# 图标生成脚本 - 为所有平台生成所需尺寸和格式的图标

SOURCE_ICON="assets/images/source/new_icon_1024.png"
TEMP_DIR="assets/images/icon_generation"

# 创建临时目录
mkdir -p "$TEMP_DIR"

echo "开始生成图标..."

# 检查源文件是否存在
if [ ! -f "$SOURCE_ICON" ]; then
    echo "错误: 源图标文件不存在: $SOURCE_ICON"
    exit 1
fi

# ========== Android 图标生成 ==========
echo "生成 Android 图标..."

# Android mipmap 尺寸 (密度倍数)
# mdpi: 1x, hdpi: 1.5x, xhdpi: 2x, xxhdpi: 3x, xxxhdpi: 4x
# 基础尺寸: 48dp (mdpi), 所以实际像素: mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192

# mdpi (48x48)
sips -z 48 48 "$SOURCE_ICON" --out "$TEMP_DIR/ic_launcher_mdpi.png"
# hdpi (72x72)
sips -z 72 72 "$SOURCE_ICON" --out "$TEMP_DIR/ic_launcher_hdpi.png"
# xhdpi (96x96)
sips -z 96 96 "$SOURCE_ICON" --out "$TEMP_DIR/ic_launcher_xhdpi.png"
# xxhdpi (144x144)
sips -z 144 144 "$SOURCE_ICON" --out "$TEMP_DIR/ic_launcher_xxhdpi.png"
# xxxhdpi (192x192)
sips -z 192 192 "$SOURCE_ICON" --out "$TEMP_DIR/ic_launcher_xxxhdpi.png"

# 转换为 WebP 格式 (需要 cwebp 工具，如果没有则使用 PNG)
if command -v cwebp &> /dev/null; then
    echo "转换为 WebP 格式..."
    cwebp -q 90 "$TEMP_DIR/ic_launcher_mdpi.png" -o "$TEMP_DIR/ic_launcher_mdpi.webp"
    cwebp -q 90 "$TEMP_DIR/ic_launcher_hdpi.png" -o "$TEMP_DIR/ic_launcher_hdpi.webp"
    cwebp -q 90 "$TEMP_DIR/ic_launcher_xhdpi.png" -o "$TEMP_DIR/ic_launcher_xhdpi.webp"
    cwebp -q 90 "$TEMP_DIR/ic_launcher_xxhdpi.png" -o "$TEMP_DIR/ic_launcher_xxhdpi.webp"
    cwebp -q 90 "$TEMP_DIR/ic_launcher_xxxhdpi.png" -o "$TEMP_DIR/ic_launcher_xxxhdpi.webp"
    
    # 复制到 Android 目录
    cp "$TEMP_DIR/ic_launcher_mdpi.webp" android/app/src/main/res/mipmap-mdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_mdpi.webp" android/app/src/main/res/mipmap-mdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_hdpi.webp" android/app/src/main/res/mipmap-hdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_hdpi.webp" android/app/src/main/res/mipmap-hdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xhdpi.webp" android/app/src/main/res/mipmap-xhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xhdpi.webp" android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xxhdpi.webp" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xxhdpi.webp" android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xxxhdpi.webp" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xxxhdpi.webp" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp
else
    echo "警告: cwebp 未安装，使用 PNG 格式..."
    # 如果没有 cwebp，直接使用 PNG
    cp "$TEMP_DIR/ic_launcher_mdpi.png" android/app/src/main/res/mipmap-mdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_mdpi.png" android/app/src/main/res/mipmap-mdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_hdpi.png" android/app/src/main/res/mipmap-hdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_hdpi.png" android/app/src/main/res/mipmap-hdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xhdpi.png" android/app/src/main/res/mipmap-xhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xhdpi.png" android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xxhdpi.png" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xxhdpi.png" android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.webp
    cp "$TEMP_DIR/ic_launcher_xxxhdpi.png" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp
    cp "$TEMP_DIR/ic_launcher_xxxhdpi.png" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.webp
fi

# Android Banner (512x512)
sips -z 512 512 "$SOURCE_ICON" --out android/app/src/main/res/mipmap-xhdpi/ic_banner.png

# ========== iOS 图标生成 ==========
echo "生成 iOS 图标..."

# iOS 主图标 (1024x1024)
cp "$SOURCE_ICON" ios/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png

# iPhone 图标
# 20pt @2x = 40px, @3x = 60px
sips -z 40 40 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-20@2x.png
sips -z 60 60 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-20@3x.png

# 29pt @2x = 58px, @3x = 87px
sips -z 58 58 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-29@2x.png
sips -z 87 87 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-29@3x.png

# 40pt @2x = 80px, @3x = 120px
sips -z 80 80 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-40@2x.png
sips -z 120 120 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-40@3x.png

# 60pt @2x = 120px, @3x = 180px
sips -z 120 120 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-60@2x.png
sips -z 180 180 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/iphone/app-icon-60@3x.png

# iPad 图标
cp "$SOURCE_ICON" ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-1024.png

# 20pt @1x = 20px, @2x = 40px
sips -z 20 20 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-20.png
sips -z 40 40 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-20@2x.png

# 29pt @1x = 29px, @2x = 58px
sips -z 29 29 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-29.png
sips -z 58 58 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-29@2x.png

# 40pt @1x = 40px, @2x = 80px
sips -z 40 40 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-40.png
sips -z 80 80 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-40@2x.png

# 76pt @1x = 76px, @2x = 152px
sips -z 76 76 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-76.png
sips -z 152 152 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-76@2x.png

# 83.5pt @2x = 167px
sips -z 167 167 "$SOURCE_ICON" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/ipad/app-icon-83.5@2x.png

# ========== macOS 图标生成 ==========
echo "生成 macOS 图标..."

# macOS 图标尺寸
sips -z 16 16 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-16.png
sips -z 32 32 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-16@2x.png
sips -z 32 32 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-32.png
sips -z 64 64 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-32@2x.png
sips -z 128 128 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-128.png
sips -z 256 256 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-128@2x.png
sips -z 256 256 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-256.png
sips -z 512 512 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-256@2x.png
sips -z 512 512 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512.png
sips -z 1024 1024 "$SOURCE_ICON" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512@2x.png
cp "$SOURCE_ICON" macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png

# ========== Windows 图标生成 ==========
echo "生成 Windows 图标..."

# Windows ICO 需要多个尺寸，使用 sips 生成然后组合
# 生成各种尺寸
sips -z 16 16 "$SOURCE_ICON" --out "$TEMP_DIR/icon_16.png"
sips -z 32 32 "$SOURCE_ICON" --out "$TEMP_DIR/icon_32.png"
sips -z 48 48 "$SOURCE_ICON" --out "$TEMP_DIR/icon_48.png"
sips -z 64 64 "$SOURCE_ICON" --out "$TEMP_DIR/icon_64.png"
sips -z 128 128 "$SOURCE_ICON" --out "$TEMP_DIR/icon_128.png"
sips -z 256 256 "$SOURCE_ICON" --out "$TEMP_DIR/icon_256.png"

# 如果有 ImageMagick 或 convert 工具，可以生成 ICO
if command -v convert &> /dev/null; then
    convert "$TEMP_DIR/icon_16.png" "$TEMP_DIR/icon_32.png" "$TEMP_DIR/icon_48.png" "$TEMP_DIR/icon_64.png" "$TEMP_DIR/icon_128.png" "$TEMP_DIR/icon_256.png" windows/runner/resources/app_icon.ico
elif command -v magick &> /dev/null; then
    magick "$TEMP_DIR/icon_16.png" "$TEMP_DIR/icon_32.png" "$TEMP_DIR/icon_48.png" "$TEMP_DIR/icon_64.png" "$TEMP_DIR/icon_128.png" "$TEMP_DIR/icon_256.png" windows/runner/resources/app_icon.ico
else
    echo "警告: 未找到 ImageMagick，使用 256x256 PNG 作为 Windows 图标"
    cp "$TEMP_DIR/icon_256.png" windows/runner/resources/app_icon.ico
fi

# ========== Web 图标生成 ==========
echo "生成 Web 图标..."
cp "$SOURCE_ICON" web/icon.png

# ========== Linux/Snap 图标生成 ==========
echo "生成 Linux/Snap 图标..."
sips -z 512 512 "$SOURCE_ICON" --out snap/gui/app_icon.png

# ========== SVG 生成 (可选) ==========
echo "生成 SVG..."
# 注意: PNG 转 SVG 不是真正的矢量图，只是将 PNG 嵌入 SVG
cat > assets/images/logo.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 1024 1024">
  <image width="1024" height="1024" xlink:href="data:image/png;base64,
EOF
# 将 PNG 转换为 base64 并添加到 SVG
base64 -i "$SOURCE_ICON" >> assets/images/logo.svg
cat >> assets/images/logo.svg << 'EOF'
"/>
</svg>
EOF

echo "图标生成完成！"
echo "已生成以下平台的图标："
echo "  - Android (所有密度)"
echo "  - iOS (iPhone/iPad)"
echo "  - macOS"
echo "  - Windows"
echo "  - Web"
echo "  - Linux/Snap"
echo "  - SVG"

