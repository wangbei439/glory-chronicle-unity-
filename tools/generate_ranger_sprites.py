#!/usr/bin/env python3
"""
《代号：传说》游侠（Ranger）像素风精灵图生成器
- 所有精灵图均使用 RGBA 模式，透明背景
- 64x64 单帧，组合成精灵图表
- 游侠：修长体型、兜帽、双匕首、深绿斗篷、暗紫轻甲
"""

from PIL import Image
import os

OUTPUT_DIR = "/home/z/my-project/godot/legend/assets/sprites/player"


# === 游侠颜色调色板 ===
class RangerPalette:
    # 兜帽/斗篷 - 深绿色系
    HOOD_DARK = (26, 58, 42, 255)       # #1a3a2a
    HOOD_MID = (45, 90, 61, 255)        # #2d5a3d
    HOOD_LIGHT = (74, 138, 93, 255)     # #4a8a5d
    HOOD_HIGHLIGHT = (106, 184, 122, 255) # #6ab87a

    # 轻甲背心 - 暗紫色系
    VEST_DARK = (42, 26, 58, 255)       # #2a1a3a
    VEST_MID = (74, 45, 90, 255)        # #4a2d5a
    VEST_LIGHT = (106, 77, 122, 255)    # #6a4d7a

    # 皮肤
    SKIN = (210, 175, 135, 255)
    SKIN_SHADOW = (175, 140, 100, 255)

    # 匕首 - 银蓝色系
    DAGGER_LIGHT = (180, 200, 220, 255)
    DAGGER_MID = (140, 160, 180, 255)
    DAGGER_DARK = (100, 120, 140, 255)
    DAGGER_HILT = (80, 55, 35, 255)
    DAGGER_WRAP = (120, 85, 50, 255)

    # 围巾 - 暗红色系
    SCARF_DARK = (120, 30, 40, 255)
    SCARF_MID = (160, 45, 55, 255)
    SCARF_LIGHT = (200, 60, 70, 255)

    # 靴子 - 暗皮革色系
    BOOT_DARK = (35, 28, 20, 255)
    BOOT_MID = (55, 42, 30, 255)

    # 裤子/腿
    PANTS_DARK = (30, 35, 40, 255)
    PANTS_MID = (45, 50, 55, 255)
    PANTS_LIGHT = (60, 65, 70, 255)

    # 腰带
    BELT_DARK = (50, 35, 25, 255)
    BELT_MID = (75, 55, 35, 255)
    BELT_BUCKLE = (160, 140, 80, 255)

    # 特效
    SPARK_WHITE = (255, 255, 240, 255)
    SPARK_CYAN = (100, 220, 255, 255)
    SPARK_GREEN = (80, 255, 140, 255)
    SHADOW_PURPLE = (80, 40, 120, 200)
    SHADOW_DARK = (30, 15, 50, 180)
    BLADE_STORM_CYAN = (120, 200, 255, 255)
    BLADE_STORM_WHITE = (220, 240, 255, 255)


def new_sprite(w=64, h=64):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def fill_rect(img, x, y, w, h, color):
    d = img.load()
    for py in range(y, y + h):
        for px in range(x, x + w):
            if 0 <= px < img.width and 0 <= py < img.height:
                d[px, py] = color


def ranger_idle(frame=0):
    """游侠待机 - 轻微呼吸，双匕首在身侧"""
    img = new_sprite()
    p = RangerPalette
    breath = [0, -1, 0, 1][frame % 4]

    # 靴子 (slim)
    fill_rect(img, 25, 55, 5, 4, p.BOOT_DARK)
    fill_rect(img, 26, 55, 3, 4, p.BOOT_MID)
    fill_rect(img, 34, 55, 5, 4, p.BOOT_DARK)
    fill_rect(img, 35, 55, 3, 4, p.BOOT_MID)

    # 裤腿 (slim, no armor)
    fill_rect(img, 25, 46+breath, 5, 9, p.PANTS_DARK)
    fill_rect(img, 26, 46+breath, 3, 9, p.PANTS_MID)
    fill_rect(img, 34, 46+breath, 5, 9, p.PANTS_DARK)
    fill_rect(img, 35, 46+breath, 3, 9, p.PANTS_MID)

    # 躯干 (slimmer than warrior: 16px wide vs 20px)
    fill_rect(img, 24, 30+breath, 16, 16, p.VEST_DARK)
    fill_rect(img, 26, 31+breath, 12, 14, p.VEST_MID)
    fill_rect(img, 28, 32+breath, 8, 12, p.VEST_LIGHT)
    fill_rect(img, 31, 32+breath, 2, 12, p.VEST_MID)  # center line

    # 腰带
    fill_rect(img, 24, 44+breath, 16, 2, p.BELT_DARK)
    fill_rect(img, 30, 44+breath, 4, 2, p.BELT_BUCKLE)

    # 兜帽 (hood over head, no helmet crest)
    fill_rect(img, 26, 12+breath, 12, 16, p.HOOD_DARK)
    fill_rect(img, 28, 13+breath, 8, 14, p.HOOD_MID)
    fill_rect(img, 30, 14+breath, 4, 12, p.HOOD_LIGHT)
    # 兜帽前沿 - 尖顶
    fill_rect(img, 28, 10+breath, 8, 3, p.HOOD_DARK)
    fill_rect(img, 30, 9+breath, 4, 2, p.HOOD_MID)
    fill_rect(img, 31, 8+breath, 2, 2, p.HOOD_LIGHT)  # tip
    # 面部阴影 (eyes visible in hood shadow)
    fill_rect(img, 29, 20+breath, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30, 20+breath, 2, 1, (180, 200, 160, 255))  # left eye glint
    fill_rect(img, 33, 20+breath, 2, 1, (180, 200, 160, 255))  # right eye glint

    # 右臂+匕首 (held at side, blade down)
    fill_rect(img, 42, 32+breath, 3, 8, p.VEST_MID)
    fill_rect(img, 43, 33+breath, 2, 6, p.SKIN)
    fill_rect(img, 43, 39+breath, 2, 3, p.DAGGER_HILT)
    fill_rect(img, 42, 40+breath, 3, 1, p.DAGGER_WRAP)
    fill_rect(img, 43, 41+breath, 2, 8, p.DAGGER_MID)
    fill_rect(img, 43, 41+breath, 1, 8, p.DAGGER_LIGHT)

    # 左臂+匕首
    fill_rect(img, 19, 32+breath, 3, 8, p.VEST_MID)
    fill_rect(img, 20, 33+breath, 2, 6, p.SKIN)
    fill_rect(img, 20, 39+breath, 2, 3, p.DAGGER_HILT)
    fill_rect(img, 19, 40+breath, 3, 1, p.DAGGER_WRAP)
    fill_rect(img, 20, 41+breath, 2, 8, p.DAGGER_MID)
    fill_rect(img, 20, 41+breath, 1, 8, p.DAGGER_LIGHT)

    # 围巾 (flowing from neck)
    scarf_sway = [0, 1, 0, -1][frame % 4]
    fill_rect(img, 24+scarf_sway, 28+breath, 3, 6, p.SCARF_DARK)
    fill_rect(img, 37+scarf_sway, 28+breath, 3, 6, p.SCARF_DARK)
    fill_rect(img, 24+scarf_sway, 28+breath, 2, 4, p.SCARF_MID)
    fill_rect(img, 37+scarf_sway, 28+breath, 2, 4, p.SCARF_MID)
    # 围巾飘尾
    fill_rect(img, 22+scarf_sway, 34+breath, 2, 4, p.SCARF_DARK)
    fill_rect(img, 23+scarf_sway, 35+breath, 2, 3, p.SCARF_LIGHT)

    # 斗篷 (behind, visible at edges)
    cloak_sway = [0, 1, 0, -1][frame % 4]
    fill_rect(img, 22+cloak_sway, 34+breath, 3, 14, p.HOOD_DARK)
    fill_rect(img, 39+cloak_sway, 34+breath, 3, 14, p.HOOD_DARK)

    return img


def ranger_run(frame=0):
    """游侠奔跑 - 斗篷飘动，前倾"""
    img = new_sprite()
    p = RangerPalette

    leg_offsets = [
        (-2, 0, 3, -2),
        (0, -1, 2, 0),
        (3, -2, -2, 0),
        (2, 0, 0, -1),
    ]
    lo = leg_offsets[frame % 4]
    lean = 2  # ranger leans more forward

    # 靴子
    fill_rect(img, 24+lo[0]+lean, 55+lo[1], 5, 4, p.BOOT_DARK)
    fill_rect(img, 25+lo[0]+lean, 55+lo[1], 3, 4, p.BOOT_MID)
    fill_rect(img, 33+lo[2]+lean, 55+lo[3], 5, 4, p.BOOT_DARK)
    fill_rect(img, 34+lo[2]+lean, 55+lo[3], 3, 4, p.BOOT_MID)

    # 裤腿
    fill_rect(img, 25+lo[0]+lean, 46+lo[1], 4, 9, p.PANTS_DARK)
    fill_rect(img, 26+lo[0]+lean, 46+lo[1], 2, 9, p.PANTS_MID)
    fill_rect(img, 34+lo[2]+lean, 46+lo[3], 4, 9, p.PANTS_DARK)
    fill_rect(img, 35+lo[2]+lean, 46+lo[3], 2, 9, p.PANTS_MID)

    # 躯干
    fill_rect(img, 24+lean, 30, 16, 16, p.VEST_DARK)
    fill_rect(img, 26+lean, 31, 12, 14, p.VEST_MID)
    fill_rect(img, 28+lean, 32, 8, 12, p.VEST_LIGHT)

    # 腰带
    fill_rect(img, 24+lean, 44, 16, 2, p.BELT_DARK)
    fill_rect(img, 30+lean, 44, 4, 2, p.BELT_BUCKLE)

    # 兜帽
    fill_rect(img, 26+lean, 12, 12, 16, p.HOOD_DARK)
    fill_rect(img, 28+lean, 13, 8, 14, p.HOOD_MID)
    fill_rect(img, 30+lean, 14, 4, 12, p.HOOD_LIGHT)
    fill_rect(img, 28+lean, 10, 8, 3, p.HOOD_DARK)
    fill_rect(img, 30+lean, 9, 4, 2, p.HOOD_MID)
    fill_rect(img, 29+lean, 20, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30+lean, 20, 2, 1, (180, 200, 160, 255))
    fill_rect(img, 33+lean, 20, 2, 1, (180, 200, 160, 255))

    # 右臂+匕首 (running position, slightly back)
    fill_rect(img, 43+lean, 32, 3, 8, p.VEST_MID)
    fill_rect(img, 44+lean, 33, 2, 6, p.SKIN)
    fill_rect(img, 44+lean, 39, 2, 3, p.DAGGER_HILT)
    fill_rect(img, 44+lean, 42, 2, 6, p.DAGGER_MID)
    fill_rect(img, 44+lean, 42, 1, 6, p.DAGGER_LIGHT)

    # 左臂+匕首
    fill_rect(img, 20+lean, 32, 3, 8, p.VEST_MID)
    fill_rect(img, 21+lean, 33, 2, 6, p.SKIN)
    fill_rect(img, 21+lean, 39, 2, 3, p.DAGGER_HILT)
    fill_rect(img, 21+lean, 42, 2, 6, p.DAGGER_MID)
    fill_rect(img, 21+lean, 42, 1, 6, p.DAGGER_LIGHT)

    # 围巾
    scarf = [2, 3, 1, 2][frame % 4]
    fill_rect(img, 24+lean, 28, 3, 5, p.SCARF_DARK)
    fill_rect(img, 37+lean, 28, 3, 5, p.SCARF_DARK)
    fill_rect(img, 21+lean+scarf, 32, 2, 5, p.SCARF_MID)
    fill_rect(img, 22+lean+scarf, 36, 2, 3, p.SCARF_LIGHT)

    # 斗篷 (flowing more when running)
    cloak = [3, 4, 2, 3][frame % 4]
    fill_rect(img, 22+lean-cloak, 34, 3, 16, p.HOOD_DARK)
    fill_rect(img, 23+lean-cloak, 36, 2, 12, p.HOOD_MID)
    fill_rect(img, 39+lean+cloak, 34, 3, 16, p.HOOD_DARK)
    fill_rect(img, 40+lean+cloak, 36, 2, 12, p.HOOD_MID)

    return img


def ranger_attack(frame=0):
    """游侠攻击 - 快速匕首连斩"""
    img = new_sprite()
    p = RangerPalette
    lean = [0, 1, 2, 1][frame]

    # 靴子
    fill_rect(img, 25, 55, 5, 4, p.BOOT_DARK)
    fill_rect(img, 26, 55, 3, 4, p.BOOT_MID)
    fill_rect(img, 34, 55, 5, 4, p.BOOT_DARK)
    fill_rect(img, 35, 55, 3, 4, p.BOOT_MID)

    # 裤腿
    fill_rect(img, 25, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 26, 46, 2, 9, p.PANTS_MID)
    fill_rect(img, 34, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 35, 46, 2, 9, p.PANTS_MID)

    # 躯干
    fill_rect(img, 24+lean, 30, 16, 16, p.VEST_DARK)
    fill_rect(img, 26+lean, 31, 12, 14, p.VEST_MID)
    fill_rect(img, 28+lean, 32, 8, 12, p.VEST_LIGHT)

    # 腰带
    fill_rect(img, 24+lean, 44, 16, 2, p.BELT_DARK)
    fill_rect(img, 30+lean, 44, 4, 2, p.BELT_BUCKLE)

    # 兜帽
    fill_rect(img, 26+lean, 12, 12, 16, p.HOOD_DARK)
    fill_rect(img, 28+lean, 13, 8, 14, p.HOOD_MID)
    fill_rect(img, 30+lean, 14, 4, 12, p.HOOD_LIGHT)
    fill_rect(img, 28+lean, 10, 8, 3, p.HOOD_DARK)
    fill_rect(img, 30+lean, 9, 4, 2, p.HOOD_MID)
    fill_rect(img, 29+lean, 20, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30+lean, 20, 2, 1, (180, 200, 160, 255))
    fill_rect(img, 33+lean, 20, 2, 1, (180, 200, 160, 255))

    # 攻击帧动画 - 双匕首
    if frame == 0:
        # 帧0: 蓄力 - 右匕首举高
        fill_rect(img, 42+lean, 26, 3, 6, p.VEST_MID)
        fill_rect(img, 43+lean, 22, 2, 5, p.SKIN)
        fill_rect(img, 43+lean, 20, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 43+lean, 8, 2, 12, p.DAGGER_MID)
        fill_rect(img, 43+lean, 8, 1, 12, p.DAGGER_LIGHT)
        # 左匕首在身侧
        fill_rect(img, 20+lean, 32, 3, 8, p.VEST_MID)
        fill_rect(img, 21+lean, 33, 2, 6, p.SKIN)
        fill_rect(img, 21+lean, 39, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 21+lean, 42, 2, 6, p.DAGGER_MID)
        fill_rect(img, 21+lean, 42, 1, 6, p.DAGGER_LIGHT)
    elif frame == 1:
        # 帧1: 右侧横斩
        fill_rect(img, 42+lean, 28, 3, 6, p.VEST_MID)
        fill_rect(img, 44+lean, 27, 2, 4, p.SKIN)
        fill_rect(img, 46+lean, 26, 2, 12, p.DAGGER_MID)
        fill_rect(img, 46+lean, 26, 1, 12, p.DAGGER_LIGHT)
        fill_rect(img, 45+lean, 37, 3, 1, p.DAGGER_WRAP)
        # 左匕首前刺
        fill_rect(img, 20+lean, 30, 3, 6, p.VEST_MID)
        fill_rect(img, 18+lean, 32, 2, 4, p.SKIN)
        fill_rect(img, 16+lean, 33, 2, 8, p.DAGGER_MID)
        fill_rect(img, 16+lean, 33, 1, 8, p.DAGGER_LIGHT)
    elif frame == 2:
        # 帧2: 交叉斩 - 双匕首交叉
        fill_rect(img, 42+lean, 30, 3, 6, p.VEST_MID)
        fill_rect(img, 44+lean, 29, 2, 4, p.SKIN)
        # 右匕首横扫
        fill_rect(img, 46+lean, 30, 12, 2, p.DAGGER_MID)
        fill_rect(img, 46+lean, 30, 12, 1, p.DAGGER_LIGHT)
        fill_rect(img, 56+lean, 29, 2, 4, p.DAGGER_LIGHT)
        # 左匕首上挑
        fill_rect(img, 20+lean, 30, 3, 6, p.VEST_MID)
        fill_rect(img, 18+lean, 29, 2, 4, p.SKIN)
        fill_rect(img, 16+lean, 28, 2, 10, p.DAGGER_MID)
        fill_rect(img, 16+lean, 28, 1, 10, p.DAGGER_LIGHT)
        # 斩击特效
        for i in range(3):
            fill_rect(img, 50+i*4, 28, 2, 1, p.SPARK_CYAN)
            fill_rect(img, 52+i*4, 32, 2, 1, p.SPARK_WHITE)
    else:
        # 帧3: 收招
        fill_rect(img, 42+lean, 32, 3, 6, p.VEST_MID)
        fill_rect(img, 43+lean, 33, 2, 4, p.SKIN)
        fill_rect(img, 43+lean, 37, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 43+lean, 40, 2, 6, p.DAGGER_MID)
        fill_rect(img, 43+lean, 40, 1, 6, p.DAGGER_LIGHT)
        fill_rect(img, 20+lean, 32, 3, 6, p.VEST_MID)
        fill_rect(img, 21+lean, 33, 2, 4, p.SKIN)
        fill_rect(img, 21+lean, 37, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 21+lean, 40, 2, 6, p.DAGGER_MID)
        fill_rect(img, 21+lean, 40, 1, 6, p.DAGGER_LIGHT)

    # 围巾
    scarf = [0, 1, 2, 1][frame]
    fill_rect(img, 24+lean, 28, 3, 5, p.SCARF_DARK)
    fill_rect(img, 37+lean, 28, 3, 5, p.SCARF_DARK)
    fill_rect(img, 22+lean+scarf, 33, 2, 4, p.SCARF_MID)

    return img


def ranger_dodge(frame=0):
    """游侠闪避 - 闪避翻滚 (替代战士格挡)"""
    img = new_sprite()
    p = RangerPalette

    if frame == 0:
        # 帧0: 蹲下侧身准备翻滚
        # 靴子
        fill_rect(img, 22, 56, 5, 4, p.BOOT_DARK)
        fill_rect(img, 23, 56, 3, 4, p.BOOT_MID)
        fill_rect(img, 38, 54, 5, 4, p.BOOT_DARK)
        fill_rect(img, 39, 54, 3, 4, p.BOOT_MID)

        # 裤腿 (crouching, shorter)
        fill_rect(img, 23, 50, 4, 6, p.PANTS_DARK)
        fill_rect(img, 24, 50, 2, 6, p.PANTS_MID)
        fill_rect(img, 38, 48, 4, 6, p.PANTS_DARK)
        fill_rect(img, 39, 48, 2, 6, p.PANTS_MID)

        # 躯干 (lowered, leaning)
        fill_rect(img, 22, 36, 18, 14, p.VEST_DARK)
        fill_rect(img, 24, 37, 14, 12, p.VEST_MID)
        fill_rect(img, 26, 38, 10, 10, p.VEST_LIGHT)

        # 腰带
        fill_rect(img, 22, 48, 18, 2, p.BELT_DARK)

        # 兜帽
        fill_rect(img, 24, 18, 12, 16, p.HOOD_DARK)
        fill_rect(img, 26, 19, 8, 14, p.HOOD_MID)
        fill_rect(img, 28, 20, 4, 12, p.HOOD_LIGHT)
        fill_rect(img, 26, 16, 8, 3, p.HOOD_DARK)
        fill_rect(img, 28, 15, 4, 2, p.HOOD_MID)
        fill_rect(img, 27, 26, 6, 2, (20, 15, 10, 255))
        fill_rect(img, 28, 26, 2, 1, (180, 200, 160, 255))
        fill_rect(img, 31, 26, 2, 1, (180, 200, 160, 255))

        # 双匕首 (held close)
        fill_rect(img, 41, 38, 3, 6, p.VEST_MID)
        fill_rect(img, 42, 39, 2, 4, p.SKIN)
        fill_rect(img, 42, 43, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 42, 46, 2, 5, p.DAGGER_MID)
        fill_rect(img, 42, 46, 1, 5, p.DAGGER_LIGHT)

        fill_rect(img, 19, 40, 3, 6, p.VEST_MID)
        fill_rect(img, 20, 41, 2, 4, p.SKIN)
        fill_rect(img, 20, 45, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 20, 48, 2, 5, p.DAGGER_MID)
        fill_rect(img, 20, 48, 1, 5, p.DAGGER_LIGHT)

        # 围巾
        fill_rect(img, 22, 34, 3, 4, p.SCARF_DARK)
        fill_rect(img, 37, 34, 3, 4, p.SCARF_DARK)

        # 闪避起始特效
        fill_rect(img, 16, 44, 3, 2, p.SPARK_CYAN)
        fill_rect(img, 14, 46, 2, 2, p.SHADOW_PURPLE)

    else:
        # 帧1: 翻滚/爆发
        # 靴子 (tucked, rolling)
        fill_rect(img, 30, 50, 5, 4, p.BOOT_DARK)
        fill_rect(img, 31, 50, 3, 4, p.BOOT_MID)

        # 裤腿 (curled up)
        fill_rect(img, 28, 44, 6, 6, p.PANTS_DARK)
        fill_rect(img, 29, 45, 4, 4, p.PANTS_MID)

        # 躯干 (rolling, compact)
        fill_rect(img, 22, 30, 18, 14, p.VEST_DARK)
        fill_rect(img, 24, 31, 14, 12, p.VEST_MID)
        fill_rect(img, 26, 32, 10, 10, p.VEST_LIGHT)

        # 腰带
        fill_rect(img, 22, 42, 18, 2, p.BELT_DARK)

        # 兜帽
        fill_rect(img, 20, 14, 12, 16, p.HOOD_DARK)
        fill_rect(img, 22, 15, 8, 14, p.HOOD_MID)
        fill_rect(img, 24, 16, 4, 12, p.HOOD_LIGHT)
        fill_rect(img, 22, 12, 8, 3, p.HOOD_DARK)
        fill_rect(img, 24, 11, 4, 2, p.HOOD_MID)
        fill_rect(img, 23, 22, 6, 2, (20, 15, 10, 255))
        fill_rect(img, 24, 22, 2, 1, (180, 200, 160, 255))
        fill_rect(img, 27, 22, 2, 1, (180, 200, 160, 255))

        # 双匕首 (tucked close)
        fill_rect(img, 17, 32, 3, 6, p.VEST_MID)
        fill_rect(img, 18, 33, 2, 4, p.SKIN)
        fill_rect(img, 18, 37, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 18, 40, 2, 4, p.DAGGER_MID)
        fill_rect(img, 18, 40, 1, 4, p.DAGGER_LIGHT)

        fill_rect(img, 41, 34, 3, 6, p.VEST_MID)
        fill_rect(img, 42, 35, 2, 4, p.SKIN)
        fill_rect(img, 42, 39, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 42, 42, 2, 4, p.DAGGER_MID)
        fill_rect(img, 42, 42, 1, 4, p.DAGGER_LIGHT)

        # 围巾
        fill_rect(img, 18, 28, 3, 5, p.SCARF_DARK)
        fill_rect(img, 38, 28, 3, 5, p.SCARF_DARK)
        fill_rect(img, 16, 32, 2, 4, p.SCARF_MID)

        # 翻滚爆发特效
        fill_rect(img, 8, 38, 6, 2, p.SPARK_CYAN)
        fill_rect(img, 10, 36, 4, 2, p.SPARK_WHITE)
        fill_rect(img, 12, 42, 3, 2, p.SHADOW_PURPLE)
        fill_rect(img, 6, 40, 4, 3, p.SHADOW_DARK)
        # 速度线
        fill_rect(img, 4, 34, 8, 1, (100, 180, 220, 150))
        fill_rect(img, 6, 38, 6, 1, (100, 180, 220, 120))

    return img


def ranger_jump(frame=0):
    """游侠跳跃 - 双匕首就绪"""
    img = new_sprite()
    p = RangerPalette

    if frame == 0:
        leg_y = 46
        leg_spread = 0
        body_y = 28
        head_y = 10
    else:
        leg_y = 48
        leg_spread = 2
        body_y = 26
        head_y = 8

    # 靴子
    fill_rect(img, 25-leg_spread, leg_y+6, 4, 4, p.BOOT_DARK)
    fill_rect(img, 26-leg_spread, leg_y+6, 2, 4, p.BOOT_MID)
    fill_rect(img, 35+leg_spread, leg_y+6, 4, 4, p.BOOT_DARK)
    fill_rect(img, 36+leg_spread, leg_y+6, 2, 4, p.BOOT_MID)

    # 裤腿
    fill_rect(img, 25-leg_spread, leg_y, 4, 6, p.PANTS_DARK)
    fill_rect(img, 26-leg_spread, leg_y, 2, 6, p.PANTS_MID)
    fill_rect(img, 35+leg_spread, leg_y, 4, 6, p.PANTS_DARK)
    fill_rect(img, 36+leg_spread, leg_y, 2, 6, p.PANTS_MID)

    # 躯干
    fill_rect(img, 24, body_y, 16, 16, p.VEST_DARK)
    fill_rect(img, 26, body_y+1, 12, 14, p.VEST_MID)
    fill_rect(img, 28, body_y+2, 8, 12, p.VEST_LIGHT)

    # 腰带
    fill_rect(img, 24, body_y+14, 16, 2, p.BELT_DARK)

    # 兜帽
    fill_rect(img, 26, head_y, 12, 16, p.HOOD_DARK)
    fill_rect(img, 28, head_y+1, 8, 14, p.HOOD_MID)
    fill_rect(img, 30, head_y+2, 4, 12, p.HOOD_LIGHT)
    fill_rect(img, 28, head_y-2, 8, 3, p.HOOD_DARK)
    fill_rect(img, 30, head_y-3, 4, 2, p.HOOD_MID)
    fill_rect(img, 29, head_y+8, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30, head_y+8, 2, 1, (180, 200, 160, 255))
    fill_rect(img, 33, head_y+8, 2, 1, (180, 200, 160, 255))

    # 双匕首 (ready position)
    if frame == 0:
        # 双匕首向下
        fill_rect(img, 42, body_y+2, 3, 6, p.VEST_MID)
        fill_rect(img, 43, body_y+8, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 43, body_y+11, 2, 8, p.DAGGER_MID)
        fill_rect(img, 43, body_y+11, 1, 8, p.DAGGER_LIGHT)

        fill_rect(img, 19, body_y+2, 3, 6, p.VEST_MID)
        fill_rect(img, 20, body_y+8, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 20, body_y+11, 2, 8, p.DAGGER_MID)
        fill_rect(img, 20, body_y+11, 1, 8, p.DAGGER_LIGHT)
    else:
        # 双匕首向两侧展开
        fill_rect(img, 42, body_y+2, 3, 6, p.VEST_MID)
        fill_rect(img, 44, body_y, 2, 12, p.DAGGER_MID)
        fill_rect(img, 44, body_y, 1, 12, p.DAGGER_LIGHT)

        fill_rect(img, 19, body_y+2, 3, 6, p.VEST_MID)
        fill_rect(img, 18, body_y, 2, 12, p.DAGGER_MID)
        fill_rect(img, 18, body_y, 1, 12, p.DAGGER_LIGHT)

    # 围巾
    fill_rect(img, 24, body_y-2, 3, 5, p.SCARF_DARK)
    fill_rect(img, 37, body_y-2, 3, 5, p.SCARF_DARK)

    # 斗篷
    fill_rect(img, 22, body_y+4, 3, 12, p.HOOD_DARK)
    fill_rect(img, 39, body_y+4, 3, 12, p.HOOD_DARK)

    return img


def ranger_hurt(frame=0):
    """游侠受击 - 击退"""
    img = new_sprite()
    p = RangerPalette
    knockback = 2 if frame == 0 else 4

    # 靴子
    fill_rect(img, 25+knockback, 55, 4, 4, p.BOOT_DARK)
    fill_rect(img, 26+knockback, 55, 2, 4, p.BOOT_MID)
    fill_rect(img, 35+knockback, 55, 4, 4, p.BOOT_DARK)
    fill_rect(img, 36+knockback, 55, 2, 4, p.BOOT_MID)

    # 裤腿
    fill_rect(img, 25+knockback, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 26+knockback, 46, 2, 9, p.PANTS_MID)
    fill_rect(img, 35+knockback, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 36+knockback, 46, 2, 9, p.PANTS_MID)

    # 躯干
    fill_rect(img, 24+knockback, 32, 16, 14, p.VEST_DARK)
    fill_rect(img, 26+knockback, 33, 12, 12, p.VEST_MID)
    fill_rect(img, 28+knockback, 34, 8, 10, p.VEST_LIGHT)

    # 腰带
    fill_rect(img, 24+knockback, 44, 16, 2, p.BELT_DARK)

    # 兜帽
    fill_rect(img, 26+knockback, 14, 12, 16, p.HOOD_DARK)
    fill_rect(img, 28+knockback, 15, 8, 14, p.HOOD_MID)
    fill_rect(img, 30+knockback, 16, 4, 12, p.HOOD_LIGHT)
    fill_rect(img, 28+knockback, 12, 8, 3, p.HOOD_DARK)
    fill_rect(img, 30+knockback, 11, 4, 2, p.HOOD_MID)
    # 受击表情
    fill_rect(img, 29+knockback, 22, 3, 2, (255, 200, 100, 255))
    fill_rect(img, 33+knockback, 22, 3, 2, (255, 200, 100, 255))

    # 手臂 (flailing)
    fill_rect(img, 18+knockback, 34, 3, 8, p.VEST_MID)
    fill_rect(img, 44+knockback, 34, 3, 8, p.VEST_MID)
    if frame == 1:
        # 匕首飞出
        fill_rect(img, 50+knockback, 40, 2, 8, p.DAGGER_MID)
        fill_rect(img, 50+knockback, 40, 1, 8, p.DAGGER_LIGHT)

    # 围巾
    fill_rect(img, 22+knockback, 30, 3, 5, p.SCARF_DARK)
    fill_rect(img, 39+knockback, 30, 3, 5, p.SCARF_DARK)

    return img


def ranger_shadow_step(frame=0):
    """游侠U技能：暗影步 - 隐入阴影 (替代战吼)"""
    img = new_sprite()
    p = RangerPalette

    if frame == 0:
        # 帧0: 消失中 - 身体渐隐，阴影粒子
        alpha = 160

        # 靴子
        fill_rect(img, 25, 55, 4, 4, (*p.BOOT_DARK[:3], alpha))
        fill_rect(img, 26, 55, 2, 4, (*p.BOOT_MID[:3], alpha))
        fill_rect(img, 35, 55, 4, 4, (*p.BOOT_DARK[:3], alpha))
        fill_rect(img, 36, 55, 2, 4, (*p.BOOT_MID[:3], alpha))

        # 裤腿
        fill_rect(img, 25, 46, 4, 9, (*p.PANTS_DARK[:3], alpha))
        fill_rect(img, 26, 46, 2, 9, (*p.PANTS_MID[:3], alpha))
        fill_rect(img, 35, 46, 4, 9, (*p.PANTS_DARK[:3], alpha))
        fill_rect(img, 36, 46, 2, 9, (*p.PANTS_MID[:3], alpha))

        # 躯干
        fill_rect(img, 24, 30, 16, 16, (*p.VEST_DARK[:3], alpha))
        fill_rect(img, 26, 31, 12, 14, (*p.VEST_MID[:3], alpha))
        fill_rect(img, 28, 32, 8, 12, (*p.VEST_LIGHT[:3], alpha))

        # 腰带
        fill_rect(img, 24, 44, 16, 2, (*p.BELT_DARK[:3], alpha))

        # 兜帽
        fill_rect(img, 26, 12, 12, 16, (*p.HOOD_DARK[:3], alpha))
        fill_rect(img, 28, 13, 8, 14, (*p.HOOD_MID[:3], alpha))
        fill_rect(img, 30, 14, 4, 12, (*p.HOOD_LIGHT[:3], alpha))
        fill_rect(img, 28, 10, 8, 3, (*p.HOOD_DARK[:3], alpha))
        fill_rect(img, 30, 9, 4, 2, (*p.HOOD_MID[:3], alpha))

        # 手臂
        fill_rect(img, 42, 32, 3, 8, (*p.VEST_MID[:3], alpha))
        fill_rect(img, 19, 32, 3, 8, (*p.VEST_MID[:3], alpha))

        # 围巾
        fill_rect(img, 24, 28, 3, 5, (*p.SCARF_DARK[:3], alpha))
        fill_rect(img, 37, 28, 3, 5, (*p.SCARF_DARK[:3], alpha))

        # 暗影消散特效
        for i in range(4):
            fill_rect(img, 18+i*6, 36, 2, 2, p.SHADOW_PURPLE)
            fill_rect(img, 42-i*6, 32, 2, 2, p.SHADOW_DARK)
        # 眼睛最后消失
        fill_rect(img, 30, 20, 2, 1, (200, 220, 255, 255))
        fill_rect(img, 33, 20, 2, 1, (200, 220, 255, 255))

    else:
        # 帧1: 重新出现 - 暗影爆发
        alpha = 255

        # 靴子
        fill_rect(img, 25, 55, 4, 4, p.BOOT_DARK)
        fill_rect(img, 26, 55, 2, 4, p.BOOT_MID)
        fill_rect(img, 35, 55, 4, 4, p.BOOT_DARK)
        fill_rect(img, 36, 55, 2, 4, p.BOOT_MID)

        # 裤腿
        fill_rect(img, 25, 46, 4, 9, p.PANTS_DARK)
        fill_rect(img, 26, 46, 2, 9, p.PANTS_MID)
        fill_rect(img, 35, 46, 4, 9, p.PANTS_DARK)
        fill_rect(img, 36, 46, 2, 9, p.PANTS_MID)

        # 躯干
        fill_rect(img, 24, 30, 16, 16, p.VEST_DARK)
        fill_rect(img, 26, 31, 12, 14, p.VEST_MID)
        fill_rect(img, 28, 32, 8, 12, p.VEST_LIGHT)

        # 腰带
        fill_rect(img, 24, 44, 16, 2, p.BELT_DARK)

        # 兜帽
        fill_rect(img, 26, 12, 12, 16, p.HOOD_DARK)
        fill_rect(img, 28, 13, 8, 14, p.HOOD_MID)
        fill_rect(img, 30, 14, 4, 12, p.HOOD_LIGHT)
        fill_rect(img, 28, 10, 8, 3, p.HOOD_DARK)
        fill_rect(img, 30, 9, 4, 2, p.HOOD_MID)
        fill_rect(img, 29, 20, 6, 2, (20, 15, 10, 255))
        fill_rect(img, 30, 20, 2, 1, (200, 220, 255, 255))
        fill_rect(img, 33, 20, 2, 1, (200, 220, 255, 255))

        # 双匕首 (ready after reappearance)
        fill_rect(img, 42, 32, 3, 8, p.VEST_MID)
        fill_rect(img, 43, 33, 2, 6, p.SKIN)
        fill_rect(img, 43, 39, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 43, 42, 2, 8, p.DAGGER_MID)
        fill_rect(img, 43, 42, 1, 8, p.DAGGER_LIGHT)

        fill_rect(img, 19, 32, 3, 8, p.VEST_MID)
        fill_rect(img, 20, 33, 2, 6, p.SKIN)
        fill_rect(img, 20, 39, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 20, 42, 2, 8, p.DAGGER_MID)
        fill_rect(img, 20, 42, 1, 8, p.DAGGER_LIGHT)

        # 围巾
        fill_rect(img, 24, 28, 3, 5, p.SCARF_DARK)
        fill_rect(img, 37, 28, 3, 5, p.SCARF_DARK)

        # 暗影爆发特效
        for i in range(6):
            fill_rect(img, 14+i*5, 24, 2, 2, p.SHADOW_PURPLE)
            fill_rect(img, 44-i*5, 20, 2, 2, p.SHADOW_DARK)
            fill_rect(img, 20+i*4, 16, 2, 2, p.SPARK_CYAN)
            fill_rect(img, 40-i*4, 16, 2, 2, p.SPARK_CYAN)
        # 暗影环绕
        fill_rect(img, 20, 40, 4, 2, p.SHADOW_PURPLE)
        fill_rect(img, 40, 40, 4, 2, p.SHADOW_PURPLE)
        fill_rect(img, 18, 36, 3, 2, p.SHADOW_DARK)
        fill_rect(img, 43, 36, 3, 2, p.SHADOW_DARK)

    return img


def ranger_blade_storm(frame=0):
    """游侠I技能：刀刃风暴 - 双匕首旋转 (替代地裂斩)"""
    img = new_sprite()
    p = RangerPalette

    # 靴子
    fill_rect(img, 25, 55, 4, 4, p.BOOT_DARK)
    fill_rect(img, 26, 55, 2, 4, p.BOOT_MID)
    fill_rect(img, 35, 55, 4, 4, p.BOOT_DARK)
    fill_rect(img, 36, 55, 2, 4, p.BOOT_MID)

    # 裤腿
    fill_rect(img, 25, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 26, 46, 2, 9, p.PANTS_MID)
    fill_rect(img, 35, 46, 4, 9, p.PANTS_DARK)
    fill_rect(img, 36, 46, 2, 9, p.PANTS_MID)

    # 腰带
    fill_rect(img, 24, 44, 16, 2, p.BELT_DARK)

    if frame == 0:
        # 帧0: 蓄力旋转 - 双匕首展开
        fill_rect(img, 24, 26, 16, 18, p.VEST_DARK)
        fill_rect(img, 26, 27, 12, 16, p.VEST_MID)
        fill_rect(img, 28, 28, 8, 14, p.VEST_LIGHT)

        # 兜帽
        fill_rect(img, 26, 8, 12, 16, p.HOOD_DARK)
        fill_rect(img, 28, 9, 8, 14, p.HOOD_MID)
        fill_rect(img, 30, 10, 4, 12, p.HOOD_LIGHT)
        fill_rect(img, 28, 6, 8, 3, p.HOOD_DARK)
        fill_rect(img, 30, 5, 4, 2, p.HOOD_MID)
        fill_rect(img, 29, 16, 6, 2, (20, 15, 10, 255))
        fill_rect(img, 30, 16, 2, 1, (200, 220, 255, 255))
        fill_rect(img, 33, 16, 2, 1, (200, 220, 255, 255))

        # 双臂展开 - 蓄力
        fill_rect(img, 42, 22, 3, 6, p.VEST_MID)
        fill_rect(img, 43, 23, 2, 4, p.SKIN)
        fill_rect(img, 43, 20, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 43, 10, 2, 10, p.DAGGER_MID)
        fill_rect(img, 43, 10, 1, 10, p.DAGGER_LIGHT)

        fill_rect(img, 19, 22, 3, 6, p.VEST_MID)
        fill_rect(img, 20, 23, 2, 4, p.SKIN)
        fill_rect(img, 20, 20, 2, 3, p.DAGGER_HILT)
        fill_rect(img, 20, 10, 2, 10, p.DAGGER_MID)
        fill_rect(img, 20, 10, 1, 10, p.DAGGER_LIGHT)

        # 蓄力绿光
        fill_rect(img, 42, 6, 4, 2, p.SPARK_GREEN)
        fill_rect(img, 18, 6, 4, 2, p.SPARK_GREEN)
        fill_rect(img, 44, 4, 2, 2, p.SPARK_CYAN)
        fill_rect(img, 18, 4, 2, 2, p.SPARK_CYAN)

    else:
        # 帧1: 全速旋转 - 刀刃龙卷风
        fill_rect(img, 24, 30, 16, 14, p.VEST_DARK)
        fill_rect(img, 26, 31, 12, 12, p.VEST_MID)
        fill_rect(img, 28, 32, 8, 10, p.VEST_LIGHT)

        # 兜帽
        fill_rect(img, 26, 12, 12, 16, p.HOOD_DARK)
        fill_rect(img, 28, 13, 8, 14, p.HOOD_MID)
        fill_rect(img, 30, 14, 4, 12, p.HOOD_LIGHT)
        fill_rect(img, 28, 10, 8, 3, p.HOOD_DARK)
        fill_rect(img, 30, 9, 4, 2, p.HOOD_MID)
        fill_rect(img, 29, 20, 6, 2, (20, 15, 10, 255))
        fill_rect(img, 30, 20, 2, 1, (200, 220, 255, 255))
        fill_rect(img, 33, 20, 2, 1, (200, 220, 255, 255))

        # 旋转匕首 - 横扫圆弧
        # 右匕首 (横扫到右侧)
        fill_rect(img, 44, 30, 3, 6, p.VEST_MID)
        fill_rect(img, 47, 28, 2, 4, p.SKIN)
        fill_rect(img, 49, 26, 14, 2, p.DAGGER_MID)
        fill_rect(img, 49, 26, 14, 1, p.DAGGER_LIGHT)
        fill_rect(img, 61, 25, 2, 4, p.DAGGER_LIGHT)

        # 左匕首 (横扫到左侧)
        fill_rect(img, 17, 30, 3, 6, p.VEST_MID)
        fill_rect(img, 14, 28, 2, 4, p.SKIN)
        fill_rect(img, 2, 26, 12, 2, p.DAGGER_MID)
        fill_rect(img, 2, 26, 12, 1, p.DAGGER_LIGHT)
        fill_rect(img, 1, 25, 2, 4, p.DAGGER_LIGHT)

        # 刀刃风暴特效 - 旋转弧线
        # 上方弧线
        for i in range(5):
            fill_rect(img, 18+i*8, 18, 2, 2, p.BLADE_STORM_CYAN)
            fill_rect(img, 42-i*8, 16, 2, 2, p.BLADE_STORM_CYAN)
        # 下方弧线
        for i in range(4):
            fill_rect(img, 20+i*8, 38, 2, 2, p.BLADE_STORM_WHITE)
            fill_rect(img, 40-i*8, 40, 2, 2, p.BLADE_STORM_WHITE)
        # 风暴粒子
        for i in range(5):
            fill_rect(img, 14+i*9, 22, 2, 1, p.SPARK_CYAN)
            fill_rect(img, 18+i*7, 34, 2, 1, p.SPARK_GREEN)

    # 围巾
    fill_rect(img, 24, 28, 3, 5, p.SCARF_DARK)
    fill_rect(img, 37, 28, 3, 5, p.SCARF_DARK)
    if frame == 1:
        # 旋转时围巾更飘逸
        fill_rect(img, 20, 32, 2, 6, p.SCARF_MID)
        fill_rect(img, 21, 36, 2, 4, p.SCARF_LIGHT)

    return img


def create_spritesheet(frames, frame_size=64, cols=4):
    """Create a sprite sheet from a list of frame images."""
    count = len(frames)
    rows = (count + cols - 1) // cols
    sheet_w = cols * frame_size
    sheet_h = rows * frame_size
    sheet = Image.new('RGBA', (sheet_w, sheet_h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        col = i % cols
        row = i // cols
        sheet.paste(frame, (col * frame_size, row * frame_size))
    return sheet


def calc_transparency(img):
    """Calculate the percentage of fully transparent pixels in an image."""
    total = img.width * img.height
    transparent = 0
    d = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if d[x, y][3] == 0:
                transparent += 1
    return (transparent / total) * 100


def main():
    print("=== 《代号：传说》游侠（Ranger）像素精灵图生成器 ===")
    print()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    animations = {
        'idle': [ranger_idle(i) for i in range(4)],
        'run': [ranger_run(i) for i in range(4)],
        'attack': [ranger_attack(i) for i in range(4)],
        'dodge': [ranger_dodge(i) for i in range(2)],
        'jump': [ranger_jump(i) for i in range(2)],
        'hurt': [ranger_hurt(i) for i in range(2)],
        'shadow_step': [ranger_shadow_step(i) for i in range(2)],
        'blade_storm': [ranger_blade_storm(i) for i in range(2)],
    }

    results = []

    # Generate individual sprite sheets
    for anim_name, frames in animations.items():
        sheet = create_spritesheet(frames, 64, len(frames))
        path = os.path.join(OUTPUT_DIR, f"ranger_{anim_name}_sheet.png")
        sheet.save(path)
        trans_pct = calc_transparency(sheet)
        results.append((path, sheet.width, sheet.height, len(frames), trans_pct))
        print(f"  ✓ ranger_{anim_name}_sheet.png  ({sheet.width}x{sheet.height}, {len(frames)} frames, {trans_pct:.1f}% transparent)")

    # Generate full sheet (512x192)
    # Layout: 8 columns, 3 rows
    # Row 0: idle(4) + run(4) = 8
    # Row 1: attack(4) + dodge(2) + jump(2) = 8
    # Row 2: hurt(2) + shadow_step(2) + blade_storm(2) + 2 empty = 8
    full_sheet = Image.new('RGBA', (512, 192), (0, 0, 0, 0))

    frame_idx = 0
    meta = {}

    for anim_name, frames in animations.items():
        start_frame = frame_idx
        for frame in frames:
            col = frame_idx % 8
            row = frame_idx // 8
            full_sheet.paste(frame, (col * 64, row * 64))
            frame_idx += 1
        meta[anim_name] = {
            'start_frame': start_frame,
            'frame_count': len(frames),
            'col': start_frame % 8,
            'row': start_frame // 8,
        }

    full_path = os.path.join(OUTPUT_DIR, "ranger_full_sheet.png")
    full_sheet.save(full_path)
    full_trans = calc_transparency(full_sheet)
    total_frames = sum(len(v) for v in animations.values())
    results.append((full_path, 512, 192, total_frames, full_trans))

    print()
    print(f"  ✓ ranger_full_sheet.png  (512x192, {total_frames} frames total, {full_trans:.1f}% transparent)")
    print()

    # Write metadata
    meta_path = os.path.join(OUTPUT_DIR, "ranger_sheet_meta.txt")
    with open(meta_path, 'w') as f:
        f.write("# Ranger (游侠) Sprite Sheet Metadata\n")
        f.write(f"# Full sheet: 512x192 (8 cols x 3 rows)\n")
        f.write(f"# Frame size: 64x64\n")
        f.write(f"# Total frames: {total_frames}\n\n")
        for anim_name, info in meta.items():
            f.write(f"[{anim_name}]\n")
            f.write(f"  start_frame = {info['start_frame']}\n")
            f.write(f"  frame_count = {info['frame_count']}\n")
            f.write(f"  col = {info['col']}\n")
            f.write(f"  row = {info['row']}\n\n")

    print(f"  ✓ ranger_sheet_meta.txt written")
    print()
    print("=== All Ranger sprites generated! ===")

    return results


if __name__ == '__main__':
    main()
