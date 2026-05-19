#!/usr/bin/env python3
"""
《代号：传说》像素风精灵图生成器
- 所有精灵图均使用 RGBA 模式，透明背景
- 统一像素画风：战士、木桩、特效
- 64x64 单帧，组合成精灵图表
"""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = "/home/z/my-project/godot/legend/assets/sprites"

# === 颜色调色板 ===
class Palette:
    # 铠甲 - 暗金色系
    ARMOR_DARK = (60, 45, 30, 255)
    ARMOR_MID = (95, 75, 45, 255)
    ARMOR_LIGHT = (140, 115, 65, 255)
    ARMOR_HIGHLIGHT = (190, 165, 95, 255)
    # 头盔
    HELM_DARK = (50, 40, 30, 255)
    HELM_MID = (80, 65, 45, 255)
    HELM_LIGHT = (120, 100, 60, 255)
    HELM_CREST = (180, 50, 30, 255)
    # 皮肤
    SKIN = (210, 175, 135, 255)
    SKIN_SHADOW = (175, 140, 100, 255)
    # 剑
    BLADE_LIGHT = (200, 210, 220, 255)
    BLADE_MID = (160, 170, 180, 255)
    BLADE_DARK = (100, 110, 120, 255)
    HILT = (100, 70, 35, 255)
    HILT_WRAP = (140, 100, 50, 255)
    # 盾
    SHIELD_DARK = (70, 55, 35, 255)
    SHIELD_MID = (110, 90, 50, 255)
    SHIELD_LIGHT = (150, 125, 70, 255)
    SHIELD_RIM = (180, 155, 90, 255)
    # 靴子
    BOOT_DARK = (40, 30, 20, 255)
    BOOT_MID = (65, 50, 30, 255)
    # 斗篷
    CLOAK_DARK = (80, 30, 25, 255)
    CLOAK_MID = (120, 45, 35, 255)
    CLOAK_LIGHT = (160, 60, 45, 255)
    # 木桩
    WOOD_DARK = (80, 55, 30, 255)
    WOOD_MID = (120, 85, 45, 255)
    WOOD_LIGHT = (155, 115, 65, 255)
    WOOD_HIGHLIGHT = (185, 150, 90, 255)
    ROPE = (150, 130, 90, 255)
    # 特效
    SPARK_WHITE = (255, 255, 240, 255)
    SPARK_YELLOW = (255, 230, 100, 255)
    SPARK_ORANGE = (255, 180, 60, 255)
    PARRY_BLUE = (100, 180, 255, 255)
    PARRY_WHITE = (200, 230, 255, 255)
    RAGE_RED = (255, 80, 40, 255)
    RAGE_ORANGE = (255, 160, 50, 255)


def new_sprite(w=64, h=64):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def fill_rect(img, x, y, w, h, color):
    d = img.load()
    for py in range(y, y + h):
        for px in range(x, x + w):
            if 0 <= px < img.width and 0 <= py < img.height:
                d[px, py] = color


def warrior_idle(frame=0):
    img = new_sprite()
    p = Palette
    breath = [0, -1, 0, 1][frame % 4]
    
    # 靴子
    fill_rect(img, 24, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 25, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35, 54, 4, 5, p.BOOT_MID)
    
    # 腿甲
    fill_rect(img, 24, 44, 6, 10, p.ARMOR_DARK)
    fill_rect(img, 25, 44, 4, 10, p.ARMOR_MID)
    fill_rect(img, 34, 44, 6, 10, p.ARMOR_DARK)
    fill_rect(img, 35, 44, 4, 10, p.ARMOR_MID)
    fill_rect(img, 23, 44, 2, 3, p.ARMOR_LIGHT)
    fill_rect(img, 33, 44, 2, 3, p.ARMOR_LIGHT)
    
    # 躯干
    fill_rect(img, 22, 28+breath, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 24, 28+breath, 16, 15, p.ARMOR_MID)
    fill_rect(img, 26, 29+breath, 12, 13, p.ARMOR_LIGHT)
    fill_rect(img, 31, 29+breath, 2, 13, p.ARMOR_MID)
    # 肩甲
    fill_rect(img, 18, 28+breath, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 19, 29+breath, 4, 4, p.ARMOR_LIGHT)
    fill_rect(img, 40, 28+breath, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 41, 29+breath, 4, 4, p.ARMOR_LIGHT)
    # 腰带
    fill_rect(img, 22, 42+breath, 20, 2, p.HILT)
    fill_rect(img, 30, 42+breath, 4, 2, p.ARMOR_HIGHLIGHT)
    
    # 头盔
    fill_rect(img, 25, 12+breath, 14, 16, p.HELM_DARK)
    fill_rect(img, 27, 13+breath, 10, 14, p.HELM_MID)
    fill_rect(img, 29, 14+breath, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29, 19+breath, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30, 19+breath, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 33, 19+breath, 2, 1, (200, 180, 100, 255))
    # 盔缨
    fill_rect(img, 29, 10+breath, 6, 3, p.HELM_CREST)
    fill_rect(img, 30, 8+breath, 4, 3, p.HELM_CREST)
    fill_rect(img, 31, 7+breath, 2, 2, (200, 70, 50, 255))
    
    # 右臂+剑
    fill_rect(img, 44, 30+breath, 4, 10, p.ARMOR_MID)
    fill_rect(img, 45, 31+breath, 2, 8, p.SKIN)
    fill_rect(img, 45, 40+breath, 2, 4, p.HILT)
    fill_rect(img, 44, 41+breath, 4, 1, p.HILT_WRAP)
    fill_rect(img, 45, 44+breath, 2, 10, p.BLADE_MID)
    fill_rect(img, 45, 44+breath, 1, 10, p.BLADE_LIGHT)
    
    # 左臂
    fill_rect(img, 16, 30+breath, 4, 10, p.ARMOR_MID)
    fill_rect(img, 17, 31+breath, 2, 8, p.SKIN)
    
    # 斗篷
    cloak_sway = [0, 1, 0, -1][frame % 4]
    fill_rect(img, 20+cloak_sway, 34+breath, 3, 12, p.CLOAK_DARK)
    fill_rect(img, 41+cloak_sway, 34+breath, 3, 12, p.CLOAK_DARK)
    
    return img


def warrior_run(frame=0):
    img = new_sprite()
    p = Palette
    
    leg_offsets = [
        (-2, 0, 4, -2),
        (0, -1, 2, 0),
        (4, -2, -2, 0),
        (2, 0, 0, -1),
    ]
    lo = leg_offsets[frame % 4]
    lean = [1, 0, 1, 0][frame % 4]
    
    # 脚
    fill_rect(img, 23+lo[0], 54+lo[1], 6, 5, p.BOOT_DARK)
    fill_rect(img, 24+lo[0], 54+lo[1], 4, 5, p.BOOT_MID)
    fill_rect(img, 33+lo[2], 54+lo[3], 6, 5, p.BOOT_DARK)
    fill_rect(img, 34+lo[2], 54+lo[3], 4, 5, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 24+lo[0], 44+lo[1], 5, 10, p.ARMOR_DARK)
    fill_rect(img, 25+lo[0], 44+lo[1], 3, 10, p.ARMOR_MID)
    fill_rect(img, 34+lo[2], 44+lo[3], 5, 10, p.ARMOR_DARK)
    fill_rect(img, 35+lo[2], 44+lo[3], 3, 10, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 22+lean, 28, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 24+lean, 29, 16, 14, p.ARMOR_MID)
    fill_rect(img, 26+lean, 30, 12, 12, p.ARMOR_LIGHT)
    fill_rect(img, 18+lean, 28, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 40+lean, 28, 6, 6, p.ARMOR_DARK)
    
    # 头盔
    fill_rect(img, 25+lean, 12, 14, 16, p.HELM_DARK)
    fill_rect(img, 27+lean, 13, 10, 14, p.HELM_MID)
    fill_rect(img, 29+lean, 14, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29+lean, 19, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30+lean, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 33+lean, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 29+lean, 10, 6, 3, p.HELM_CREST)
    fill_rect(img, 30+lean, 8, 4, 3, p.HELM_CREST)
    
    # 右臂+剑
    fill_rect(img, 44+lean, 30, 4, 8, p.ARMOR_MID)
    fill_rect(img, 45+lean, 38, 2, 3, p.HILT)
    fill_rect(img, 45+lean, 41, 2, 8, p.BLADE_MID)
    fill_rect(img, 45+lean, 41, 1, 8, p.BLADE_LIGHT)
    
    # 左臂
    fill_rect(img, 16+lean, 30, 4, 8, p.ARMOR_MID)
    
    # 斗篷
    cloak = [2, 3, 1, 2][frame % 4]
    fill_rect(img, 20+lean-cloak, 34, 3, 14, p.CLOAK_DARK)
    fill_rect(img, 41+lean+cloak, 34, 3, 14, p.CLOAK_DARK)
    
    return img


def warrior_attack(frame=0):
    img = new_sprite()
    p = Palette
    
    lean = [0, 1, 2, 1][frame]
    
    # 脚
    fill_rect(img, 22, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 23, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35, 54, 4, 5, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 23, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 24, 44, 3, 10, p.ARMOR_MID)
    fill_rect(img, 35, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 36, 44, 3, 10, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 22+lean, 28, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 24+lean, 29, 16, 14, p.ARMOR_MID)
    fill_rect(img, 26+lean, 30, 12, 12, p.ARMOR_LIGHT)
    fill_rect(img, 18+lean, 28, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 19+lean, 29, 4, 4, p.ARMOR_LIGHT)
    fill_rect(img, 40+lean, 28, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 41+lean, 29, 4, 4, p.ARMOR_LIGHT)
    
    # 头盔
    fill_rect(img, 25+lean, 12, 14, 16, p.HELM_DARK)
    fill_rect(img, 27+lean, 13, 10, 14, p.HELM_MID)
    fill_rect(img, 29+lean, 14, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29+lean, 19, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30+lean, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 33+lean, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 29+lean, 10, 6, 3, p.HELM_CREST)
    fill_rect(img, 30+lean, 8, 4, 3, p.HELM_CREST)
    
    # 右臂+剑 - 不同攻击帧
    if frame == 0:
        fill_rect(img, 44+lean, 24, 4, 6, p.ARMOR_MID)
        fill_rect(img, 44+lean, 20, 4, 4, p.SKIN)
        fill_rect(img, 45, 6, 2, 14, p.BLADE_MID)
        fill_rect(img, 45, 6, 1, 14, p.BLADE_LIGHT)
        fill_rect(img, 44, 18, 4, 2, p.HILT_WRAP)
    elif frame == 1:
        fill_rect(img, 44+lean, 24, 4, 8, p.ARMOR_MID)
        fill_rect(img, 47, 20, 4, 4, p.SKIN)
        fill_rect(img, 49, 18, 2, 14, p.BLADE_MID)
        fill_rect(img, 49, 18, 1, 14, p.BLADE_LIGHT)
        fill_rect(img, 48, 30, 4, 2, p.HILT_WRAP)
    elif frame == 2:
        fill_rect(img, 44+lean, 28, 4, 6, p.ARMOR_MID)
        fill_rect(img, 47, 29, 4, 4, p.SKIN)
        fill_rect(img, 49, 30, 14, 2, p.BLADE_MID)
        fill_rect(img, 49, 30, 14, 1, p.BLADE_LIGHT)
        fill_rect(img, 61, 29, 2, 4, p.BLADE_LIGHT)
        fill_rect(img, 48, 31, 2, 2, p.HILT_WRAP)
        for i in range(3):
            fill_rect(img, 52+i*4, 28, 2, 1, p.SPARK_WHITE)
            fill_rect(img, 54+i*4, 32, 2, 1, p.SPARK_YELLOW)
    else:
        fill_rect(img, 44+lean, 30, 4, 6, p.ARMOR_MID)
        fill_rect(img, 46, 34, 4, 3, p.SKIN)
        fill_rect(img, 48, 36, 2, 10, p.BLADE_MID)
        fill_rect(img, 48, 36, 1, 10, p.BLADE_LIGHT)
        fill_rect(img, 47, 37, 3, 1, p.HILT_WRAP)
    
    # 左臂
    fill_rect(img, 16+lean, 30, 4, 8, p.ARMOR_MID)
    fill_rect(img, 17+lean, 31, 2, 6, p.SKIN)
    
    return img


def warrior_guard(frame=0):
    img = new_sprite()
    p = Palette
    shake = 0 if frame == 0 else 1
    
    # 脚
    fill_rect(img, 22+shake, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 23+shake, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34+shake, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35+shake, 54, 4, 5, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 23+shake, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 24+shake, 44, 3, 10, p.ARMOR_MID)
    fill_rect(img, 35+shake, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 36+shake, 44, 3, 10, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 21+shake, 28, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 23+shake, 29, 16, 14, p.ARMOR_MID)
    fill_rect(img, 25+shake, 30, 12, 12, p.ARMOR_LIGHT)
    fill_rect(img, 17+shake, 28, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 39+shake, 28, 6, 6, p.ARMOR_DARK)
    
    # 头盔
    fill_rect(img, 24+shake, 12, 14, 16, p.HELM_DARK)
    fill_rect(img, 26+shake, 13, 10, 14, p.HELM_MID)
    fill_rect(img, 28+shake, 14, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 28+shake, 19, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 29+shake, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 32+shake, 19, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 28+shake, 10, 6, 3, p.HELM_CREST)
    fill_rect(img, 29+shake, 8, 4, 3, p.HELM_CREST)
    
    # 盾牌
    fill_rect(img, 14+shake, 22, 8, 18, p.SHIELD_DARK)
    fill_rect(img, 15+shake, 23, 6, 16, p.SHIELD_MID)
    fill_rect(img, 16+shake, 24, 4, 14, p.SHIELD_LIGHT)
    fill_rect(img, 17+shake, 25, 2, 12, p.SHIELD_RIM)
    fill_rect(img, 14+shake, 22, 8, 1, p.SHIELD_RIM)
    fill_rect(img, 14+shake, 39, 8, 1, p.SHIELD_RIM)
    
    # 右臂+剑
    fill_rect(img, 42+shake, 26, 4, 8, p.ARMOR_MID)
    fill_rect(img, 43+shake, 27, 2, 6, p.SKIN)
    fill_rect(img, 43+shake, 33, 2, 3, p.HILT)
    fill_rect(img, 43+shake, 36, 2, 8, p.BLADE_MID)
    fill_rect(img, 43+shake, 36, 1, 8, p.BLADE_LIGHT)
    
    # 完美格挡火花
    if frame == 1:
        fill_rect(img, 12, 20, 3, 2, p.PARRY_BLUE)
        fill_rect(img, 10, 22, 2, 2, p.PARRY_WHITE)
        fill_rect(img, 13, 18, 2, 2, p.PARRY_WHITE)
    
    return img


def warrior_jump(frame=0):
    img = new_sprite()
    p = Palette
    
    if frame == 0:
        leg_y = 46
        leg_spread = 0
    else:
        leg_y = 48
        leg_spread = 2
    
    # 脚
    fill_rect(img, 24-leg_spread, leg_y+6, 5, 4, p.BOOT_DARK)
    fill_rect(img, 25-leg_spread, leg_y+6, 3, 4, p.BOOT_MID)
    fill_rect(img, 35+leg_spread, leg_y+6, 5, 4, p.BOOT_DARK)
    fill_rect(img, 36+leg_spread, leg_y+6, 3, 4, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 24-leg_spread, leg_y, 5, 6, p.ARMOR_DARK)
    fill_rect(img, 25-leg_spread, leg_y, 3, 6, p.ARMOR_MID)
    fill_rect(img, 35+leg_spread, leg_y, 5, 6, p.ARMOR_DARK)
    fill_rect(img, 36+leg_spread, leg_y, 3, 6, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 22, 26, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 24, 27, 16, 14, p.ARMOR_MID)
    fill_rect(img, 26, 28, 12, 12, p.ARMOR_LIGHT)
    fill_rect(img, 18, 26, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 40, 26, 6, 6, p.ARMOR_DARK)
    
    # 头盔
    fill_rect(img, 25, 10, 14, 16, p.HELM_DARK)
    fill_rect(img, 27, 11, 10, 14, p.HELM_MID)
    fill_rect(img, 29, 12, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29, 17, 6, 2, (20, 15, 10, 255))
    fill_rect(img, 30, 17, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 33, 17, 2, 1, (200, 180, 100, 255))
    fill_rect(img, 29, 8, 6, 3, p.HELM_CREST)
    fill_rect(img, 30, 6, 4, 3, p.HELM_CREST)
    
    # 右臂+剑
    if frame == 0:
        fill_rect(img, 44, 20, 4, 6, p.ARMOR_MID)
        fill_rect(img, 45, 10, 2, 12, p.BLADE_MID)
        fill_rect(img, 45, 10, 1, 12, p.BLADE_LIGHT)
        fill_rect(img, 44, 20, 4, 2, p.HILT_WRAP)
    else:
        fill_rect(img, 44, 28, 4, 6, p.ARMOR_MID)
        fill_rect(img, 46, 34, 2, 12, p.BLADE_MID)
        fill_rect(img, 46, 34, 1, 12, p.BLADE_LIGHT)
    
    # 左臂
    fill_rect(img, 16, 28, 4, 8, p.ARMOR_MID)
    
    # 斗篷
    fill_rect(img, 20, 32, 3, 12, p.CLOAK_DARK)
    fill_rect(img, 41, 32, 3, 12, p.CLOAK_DARK)
    
    return img


def warrior_hurt(frame=0):
    img = new_sprite()
    p = Palette
    knockback = 2 if frame == 0 else 3
    
    # 脚
    fill_rect(img, 22+knockback, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 23+knockback, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34+knockback, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35+knockback, 54, 4, 5, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 23+knockback, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 24+knockback, 44, 3, 10, p.ARMOR_MID)
    fill_rect(img, 35+knockback, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 36+knockback, 44, 3, 10, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 22+knockback, 30, 20, 14, p.ARMOR_DARK)
    fill_rect(img, 24+knockback, 31, 16, 12, p.ARMOR_MID)
    fill_rect(img, 26+knockback, 32, 12, 10, p.ARMOR_LIGHT)
    fill_rect(img, 18+knockback, 30, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 40+knockback, 30, 6, 6, p.ARMOR_DARK)
    
    # 头盔
    fill_rect(img, 25+knockback, 14, 14, 16, p.HELM_DARK)
    fill_rect(img, 27+knockback, 15, 10, 14, p.HELM_MID)
    fill_rect(img, 29+knockback, 16, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29+knockback, 21, 3, 2, (255, 200, 100, 255))
    fill_rect(img, 33+knockback, 21, 3, 2, (255, 200, 100, 255))
    fill_rect(img, 29+knockback, 12, 6, 3, p.HELM_CREST)
    fill_rect(img, 30+knockback, 10, 4, 3, p.HELM_CREST)
    
    # 手臂
    fill_rect(img, 14+knockback, 32, 5, 8, p.ARMOR_MID)
    fill_rect(img, 45+knockback, 32, 5, 8, p.ARMOR_MID)
    if frame == 1:
        fill_rect(img, 52+knockback, 38, 2, 10, p.BLADE_MID)
        fill_rect(img, 52+knockback, 38, 1, 10, p.BLADE_LIGHT)
    
    return img


def warrior_skill_war_cry(frame=0):
    img = new_sprite()
    p = Palette
    
    # 基础身体
    fill_rect(img, 24, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 25, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 24, 44, 6, 10, p.ARMOR_DARK)
    fill_rect(img, 25, 44, 4, 10, p.ARMOR_MID)
    fill_rect(img, 34, 44, 6, 10, p.ARMOR_DARK)
    fill_rect(img, 35, 44, 4, 10, p.ARMOR_MID)
    
    # 躯干
    fill_rect(img, 22, 28, 20, 16, p.ARMOR_DARK)
    fill_rect(img, 24, 29, 16, 14, p.ARMOR_MID)
    fill_rect(img, 26, 30, 12, 12, p.ARMOR_LIGHT)
    fill_rect(img, 18, 28, 6, 6, p.ARMOR_DARK)
    fill_rect(img, 40, 28, 6, 6, p.ARMOR_DARK)
    
    # 头盔
    fill_rect(img, 25, 10, 14, 16, p.HELM_DARK)
    fill_rect(img, 27, 11, 10, 14, p.HELM_MID)
    fill_rect(img, 29, 12, 6, 12, p.HELM_LIGHT)
    fill_rect(img, 29, 17, 6, 3, (30, 20, 15, 255))
    fill_rect(img, 30, 17, 4, 1, (255, 100, 80, 255))
    fill_rect(img, 29, 8, 6, 3, p.HELM_CREST)
    fill_rect(img, 30, 6, 4, 3, (200, 60, 40, 255))
    
    # 双臂举起
    fill_rect(img, 14, 18, 5, 12, p.ARMOR_MID)
    fill_rect(img, 15, 16, 3, 4, p.SKIN)
    fill_rect(img, 45, 18, 5, 12, p.ARMOR_MID)
    fill_rect(img, 46, 16, 3, 4, p.SKIN)
    
    # 战吼光环
    if frame == 0:
        for i in range(4):
            fill_rect(img, 20+i*4, 24, 2, 2, p.RAGE_ORANGE)
            fill_rect(img, 40-i*4, 24, 2, 2, p.RAGE_RED)
    else:
        for i in range(6):
            fill_rect(img, 16+i*3, 20, 2, 2, p.RAGE_ORANGE)
            fill_rect(img, 44-i*3, 20, 2, 2, p.RAGE_RED)
            fill_rect(img, 22+i*3, 14, 2, 2, p.SPARK_YELLOW)
            fill_rect(img, 38-i*3, 14, 2, 2, p.SPARK_YELLOW)
    
    return img


def warrior_skill_earth_shatter(frame=0):
    img = new_sprite()
    p = Palette
    
    # 脚
    fill_rect(img, 22, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 23, 54, 4, 5, p.BOOT_MID)
    fill_rect(img, 34, 54, 6, 5, p.BOOT_DARK)
    fill_rect(img, 35, 54, 4, 5, p.BOOT_MID)
    
    # 腿
    fill_rect(img, 23, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 24, 44, 3, 10, p.ARMOR_MID)
    fill_rect(img, 35, 44, 5, 10, p.ARMOR_DARK)
    fill_rect(img, 36, 44, 3, 10, p.ARMOR_MID)
    
    if frame == 0:
        # 蓄力
        fill_rect(img, 22, 24, 20, 16, p.ARMOR_DARK)
        fill_rect(img, 24, 25, 16, 14, p.ARMOR_MID)
        fill_rect(img, 26, 26, 12, 12, p.ARMOR_LIGHT)
        fill_rect(img, 25, 8, 14, 16, p.HELM_DARK)
        fill_rect(img, 27, 9, 10, 14, p.HELM_MID)
        fill_rect(img, 29, 10, 6, 12, p.HELM_LIGHT)
        fill_rect(img, 29, 6, 6, 3, p.HELM_CREST)
        fill_rect(img, 44, 12, 4, 6, p.ARMOR_MID)
        fill_rect(img, 45, 0, 2, 14, p.BLADE_MID)
        fill_rect(img, 45, 0, 1, 14, p.BLADE_LIGHT)
        fill_rect(img, 44, 2, 4, 2, p.SPARK_YELLOW)
        fill_rect(img, 44, 6, 4, 2, p.RAGE_ORANGE)
    else:
        # 劈下
        fill_rect(img, 22, 28, 20, 16, p.ARMOR_DARK)
        fill_rect(img, 24, 29, 16, 14, p.ARMOR_MID)
        fill_rect(img, 26, 30, 12, 12, p.ARMOR_LIGHT)
        fill_rect(img, 25, 12, 14, 16, p.HELM_DARK)
        fill_rect(img, 27, 13, 10, 14, p.HELM_MID)
        fill_rect(img, 29, 14, 6, 12, p.HELM_LIGHT)
        fill_rect(img, 29, 10, 6, 3, p.HELM_CREST)
        fill_rect(img, 44, 30, 4, 6, p.ARMOR_MID)
        fill_rect(img, 45, 36, 2, 20, p.BLADE_MID)
        fill_rect(img, 45, 36, 1, 20, p.BLADE_LIGHT)
        for i in range(5):
            fill_rect(img, 20+i*6, 56, 3, 3, p.RAGE_ORANGE)
            fill_rect(img, 22+i*6, 54, 2, 2, p.SPARK_YELLOW)
            fill_rect(img, 18+i*6, 58, 2, 2, p.RAGE_RED)
    
    return img


# ============================================================
# 矿脉甲虫 Boss (96x64 大尺寸)
# ============================================================

class BeetlePalette:
    # 甲壳 - 深蓝金属色
    SHELL_DARK = (20, 30, 50, 255)
    SHELL_MID = (35, 55, 85, 255)
    SHELL_LIGHT = (55, 80, 120, 255)
    SHELL_HIGHLIGHT = (80, 120, 170, 255)
    SHELL_GLOW = (100, 160, 220, 255)  # 矿脉发光
    # 腹部
    BELLY_DARK = (30, 25, 20, 255)
    BELLY_MID = (50, 40, 30, 255)
    BELLY_LIGHT = (70, 55, 40, 255)
    # 腿
    LEG_DARK = (25, 20, 15, 255)
    LEG_MID = (45, 35, 25, 255)
    LEG_LIGHT = (65, 50, 35, 255)
    # 大颚
    MANDIBLE_DARK = (40, 35, 25, 255)
    MANDIBLE_MID = (70, 60, 40, 255)
    MANDIBLE_LIGHT = (100, 85, 55, 255)
    MANDIBLE_TIP = (180, 160, 100, 255)  # 尖端
    # 眼睛
    EYE_GLOW = (255, 200, 50, 255)  # 金色发光
    EYE_DARK = (180, 120, 20, 255)
    # 矿脉晶体（甲壳上的金色矿脉）
    CRYSTAL_DARK = (120, 90, 30, 255)
    CRYSTAL_MID = (180, 140, 50, 255)
    CRYSTAL_LIGHT = (230, 200, 80, 255)
    CRYSTAL_GLOW = (255, 240, 150, 255)
    # 触角
    ANTENNA = (50, 40, 30, 255)
    ANTENNA_TIP = (200, 180, 80, 255)


def boss_beetle_idle(frame=0):
    """矿脉甲虫待机 - 身体微微起伏 (4帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    breath = [0, -1, 0, 1][frame % 4]
    
    # === 腿 (6条，3对) ===
    # 左侧3条腿
    for i, (lx, ly) in enumerate([(10, 48), (18, 50), (26, 48)]):
        offset = 1 if (frame + i) % 4 < 2 else 0
        fill_rect(img, lx, ly+offset, 6, 3, bp.LEG_DARK)
        fill_rect(img, lx+1, ly+offset, 4, 2, bp.LEG_MID)
        fill_rect(img, lx+2, ly+offset, 2, 1, bp.LEG_LIGHT)
    # 右侧3条腿
    for i, (rx, ry) in enumerate([(62, 48), (70, 50), (78, 48)]):
        offset = 1 if (frame + i) % 4 >= 2 else 0
        fill_rect(img, rx, ry+offset, 6, 3, bp.LEG_DARK)
        fill_rect(img, rx+1, ry+offset, 4, 2, bp.LEG_MID)
        fill_rect(img, rx+2, ry+offset, 2, 1, bp.LEG_LIGHT)
    
    # === 腹部 ===
    fill_rect(img, 20, 42+breath, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22, 43+breath, 52, 6, bp.BELLY_MID)
    fill_rect(img, 26, 44+breath, 44, 4, bp.BELLY_LIGHT)
    # 腹部纹路
    fill_rect(img, 36, 43+breath, 2, 5, bp.BELLY_DARK)
    fill_rect(img, 46, 43+breath, 2, 5, bp.BELLY_DARK)
    fill_rect(img, 56, 43+breath, 2, 5, bp.BELLY_DARK)
    
    # === 甲壳（主体）===
    fill_rect(img, 16, 20+breath, 64, 24, bp.SHELL_DARK)
    fill_rect(img, 18, 21+breath, 60, 22, bp.SHELL_MID)
    fill_rect(img, 22, 22+breath, 52, 20, bp.SHELL_LIGHT)
    fill_rect(img, 28, 23+breath, 40, 18, bp.SHELL_HIGHLIGHT)
    # 甲壳中线
    fill_rect(img, 47, 20+breath, 2, 24, bp.SHELL_DARK)
    # 甲壳横纹
    for i in range(3):
        fill_rect(img, 20, 26+i*6+breath, 56, 1, bp.SHELL_MID)
    
    # === 矿脉晶体（甲壳上的金色纹理）===
    # 晶体1
    fill_rect(img, 28, 24+breath, 4, 6, bp.CRYSTAL_DARK)
    fill_rect(img, 29, 25+breath, 2, 4, bp.CRYSTAL_MID)
    fill_rect(img, 30, 26+breath, 1, 2, bp.CRYSTAL_LIGHT)
    # 晶体2
    fill_rect(img, 62, 26+breath, 4, 6, bp.CRYSTAL_DARK)
    fill_rect(img, 63, 27+breath, 2, 4, bp.CRYSTAL_MID)
    fill_rect(img, 64, 28+breath, 1, 2, bp.CRYSTAL_LIGHT)
    # 晶体3（大的，中间）
    fill_rect(img, 42, 22+breath, 12, 8, bp.CRYSTAL_DARK)
    fill_rect(img, 44, 23+breath, 8, 6, bp.CRYSTAL_MID)
    fill_rect(img, 46, 24+breath, 4, 4, bp.CRYSTAL_LIGHT)
    # 晶体发光
    glow_flicker = 2 if frame % 4 == 0 else 0
    fill_rect(img, 47, 25+breath+glow_flicker, 2, 2, bp.CRYSTAL_GLOW)
    
    # === 头部 ===
    fill_rect(img, 34, 12+breath, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36, 13+breath, 24, 10, bp.SHELL_MID)
    fill_rect(img, 38, 14+breath, 20, 8, bp.SHELL_LIGHT)
    # 眼睛
    fill_rect(img, 36, 16+breath, 4, 3, bp.EYE_DARK)
    fill_rect(img, 37, 17+breath, 2, 1, bp.EYE_GLOW)
    fill_rect(img, 56, 16+breath, 4, 3, bp.EYE_DARK)
    fill_rect(img, 57, 17+breath, 2, 1, bp.EYE_GLOW)
    
    # === 大颚 ===
    # 左颚
    fill_rect(img, 28, 18+breath, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 29, 19+breath, 6, 2, bp.MANDIBLE_MID)
    fill_rect(img, 26, 20+breath, 4, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 24, 21+breath, 3, 1, bp.MANDIBLE_TIP)
    # 右颚
    fill_rect(img, 60, 18+breath, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 61, 19+breath, 6, 2, bp.MANDIBLE_MID)
    fill_rect(img, 66, 20+breath, 4, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 69, 21+breath, 3, 1, bp.MANDIBLE_TIP)
    
    # === 触角 ===
    fill_rect(img, 38, 8+breath, 2, 5, bp.ANTENNA)
    fill_rect(img, 36, 6+breath, 3, 3, bp.ANTENNA)
    fill_rect(img, 37, 5+breath, 1, 2, bp.ANTENNA_TIP)
    fill_rect(img, 56, 8+breath, 2, 5, bp.ANTENNA)
    fill_rect(img, 57, 6+breath, 3, 3, bp.ANTENNA)
    fill_rect(img, 58, 5+breath, 1, 2, bp.ANTENNA_TIP)
    
    return img


def boss_beetle_walk(frame=0):
    """矿脉甲虫行走 (4帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    
    # 走路腿部动画
    leg_anim = [
        [(10, 47), (18, 49), (26, 47), (62, 49), (70, 47), (78, 49)],
        [(10, 49), (18, 47), (26, 49), (62, 47), (70, 49), (78, 47)],
        [(10, 47), (18, 49), (26, 47), (62, 49), (70, 47), (78, 49)],
        [(10, 49), (18, 47), (26, 49), (62, 47), (70, 49), (78, 47)],
    ]
    
    # 腿
    for i, (lx, ly) in enumerate(leg_anim[frame % 4]):
        fill_rect(img, lx, ly, 6, 3, bp.LEG_DARK)
        fill_rect(img, lx+1, ly, 4, 2, bp.LEG_MID)
    
    # 腹部
    bob = [0, -1, 0, 1][frame % 4]
    fill_rect(img, 20, 42+bob, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22, 43+bob, 52, 6, bp.BELLY_MID)
    fill_rect(img, 26, 44+bob, 44, 4, bp.BELLY_LIGHT)
    fill_rect(img, 36, 43+bob, 2, 5, bp.BELLY_DARK)
    fill_rect(img, 46, 43+bob, 2, 5, bp.BELLY_DARK)
    fill_rect(img, 56, 43+bob, 2, 5, bp.BELLY_DARK)
    
    # 甲壳
    fill_rect(img, 16, 20+bob, 64, 24, bp.SHELL_DARK)
    fill_rect(img, 18, 21+bob, 60, 22, bp.SHELL_MID)
    fill_rect(img, 22, 22+bob, 52, 20, bp.SHELL_LIGHT)
    fill_rect(img, 28, 23+bob, 40, 18, bp.SHELL_HIGHLIGHT)
    fill_rect(img, 47, 20+bob, 2, 24, bp.SHELL_DARK)
    
    # 矿脉晶体
    fill_rect(img, 28, 24+bob, 4, 6, bp.CRYSTAL_DARK)
    fill_rect(img, 29, 25+bob, 2, 4, bp.CRYSTAL_MID)
    fill_rect(img, 62, 26+bob, 4, 6, bp.CRYSTAL_DARK)
    fill_rect(img, 63, 27+bob, 2, 4, bp.CRYSTAL_MID)
    fill_rect(img, 42, 22+bob, 12, 8, bp.CRYSTAL_DARK)
    fill_rect(img, 44, 23+bob, 8, 6, bp.CRYSTAL_MID)
    fill_rect(img, 46, 24+bob, 4, 4, bp.CRYSTAL_LIGHT)
    fill_rect(img, 47, 25+bob, 2, 2, bp.CRYSTAL_GLOW)
    
    # 头部
    fill_rect(img, 34, 12+bob, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36, 13+bob, 24, 10, bp.SHELL_MID)
    fill_rect(img, 38, 14+bob, 20, 8, bp.SHELL_LIGHT)
    fill_rect(img, 36, 16+bob, 4, 3, bp.EYE_DARK)
    fill_rect(img, 37, 17+bob, 2, 1, bp.EYE_GLOW)
    fill_rect(img, 56, 16+bob, 4, 3, bp.EYE_DARK)
    fill_rect(img, 57, 17+bob, 2, 1, bp.EYE_GLOW)
    
    # 大颚
    fill_rect(img, 28, 18+bob, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 29, 19+bob, 6, 2, bp.MANDIBLE_MID)
    fill_rect(img, 26, 20+bob, 4, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 24, 21+bob, 3, 1, bp.MANDIBLE_TIP)
    fill_rect(img, 60, 18+bob, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 61, 19+bob, 6, 2, bp.MANDIBLE_MID)
    fill_rect(img, 66, 20+bob, 4, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 69, 21+bob, 3, 1, bp.MANDIBLE_TIP)
    
    # 触角
    fill_rect(img, 38, 8+bob, 2, 5, bp.ANTENNA)
    fill_rect(img, 36, 6+bob, 3, 3, bp.ANTENNA)
    fill_rect(img, 37, 5+bob, 1, 2, bp.ANTENNA_TIP)
    fill_rect(img, 56, 8+bob, 2, 5, bp.ANTENNA)
    fill_rect(img, 57, 6+bob, 3, 3, bp.ANTENNA)
    fill_rect(img, 58, 5+bob, 1, 2, bp.ANTENNA_TIP)
    
    return img


def boss_beetle_attack(frame=0):
    """矿脉甲虫攻击 - 大颚夹击 (4帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    
    # 帧0: 张颚蓄力, 帧1: 继续, 帧2: 夹击!, 帧3: 收招
    jaw_open = [4, 6, 0, 2][frame]
    jaw_y_offset = [0, -1, 2, 1][frame]
    
    # 腿
    for lx, ly in [(10, 48), (18, 50), (26, 48), (62, 48), (70, 50), (78, 48)]:
        fill_rect(img, lx, ly, 6, 3, bp.LEG_DARK)
        fill_rect(img, lx+1, ly, 4, 2, bp.LEG_MID)
    
    # 腹部
    fill_rect(img, 20, 42, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22, 43, 52, 6, bp.BELLY_MID)
    fill_rect(img, 26, 44, 44, 4, bp.BELLY_LIGHT)
    
    # 甲壳
    fill_rect(img, 16, 20, 64, 24, bp.SHELL_DARK)
    fill_rect(img, 18, 21, 60, 22, bp.SHELL_MID)
    fill_rect(img, 22, 22, 52, 20, bp.SHELL_LIGHT)
    fill_rect(img, 28, 23, 40, 18, bp.SHELL_HIGHLIGHT)
    fill_rect(img, 47, 20, 2, 24, bp.SHELL_DARK)
    
    # 矿脉晶体
    fill_rect(img, 42, 22, 12, 8, bp.CRYSTAL_DARK)
    fill_rect(img, 44, 23, 8, 6, bp.CRYSTAL_MID)
    fill_rect(img, 46, 24, 4, 4, bp.CRYSTAL_LIGHT)
    if frame == 2:
        fill_rect(img, 46, 24, 4, 4, bp.CRYSTAL_GLOW)
    
    # 头部
    head_y = 12 + jaw_y_offset
    fill_rect(img, 34, head_y, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36, head_y+1, 24, 10, bp.SHELL_MID)
    fill_rect(img, 38, head_y+2, 20, 8, bp.SHELL_LIGHT)
    # 眼睛（攻击时更亮）
    fill_rect(img, 36, head_y+4, 4, 3, bp.EYE_GLOW)
    fill_rect(img, 37, head_y+5, 2, 1, (255, 255, 200, 255))
    fill_rect(img, 56, head_y+4, 4, 3, bp.EYE_GLOW)
    fill_rect(img, 57, head_y+5, 2, 1, (255, 255, 200, 255))
    
    # 大颚（张合动画）
    jaw_y = head_y + 6
    # 左颚
    fill_rect(img, 28-jaw_open, jaw_y, 8+jaw_open, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 29-jaw_open, jaw_y+1, 6+jaw_open, 2, bp.MANDIBLE_MID)
    fill_rect(img, 24-jaw_open, jaw_y+2, 6, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 22-jaw_open, jaw_y+3, 3, 1, bp.MANDIBLE_TIP)
    # 右颚
    fill_rect(img, 60, jaw_y, 8+jaw_open, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 61, jaw_y+1, 6+jaw_open, 2, bp.MANDIBLE_MID)
    fill_rect(img, 66+jaw_open, jaw_y+2, 6, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 71+jaw_open, jaw_y+3, 3, 1, bp.MANDIBLE_TIP)
    
    # 触角
    fill_rect(img, 38, head_y-4, 2, 5, bp.ANTENNA)
    fill_rect(img, 36, head_y-6, 3, 3, bp.ANTENNA)
    fill_rect(img, 56, head_y-4, 2, 5, bp.ANTENNA)
    fill_rect(img, 57, head_y-6, 3, 3, bp.ANTENNA)
    
    # 夹击特效
    if frame == 2:
        fill_rect(img, 40, jaw_y, 16, 4, (255, 220, 100, 200))
        fill_rect(img, 44, jaw_y+1, 8, 2, (255, 255, 200, 255))
    
    return img


def boss_beetle_charge(frame=0):
    """矿脉甲虫冲锋 (2帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    shake = 0 if frame == 0 else 1
    
    # 腿（快速移动）
    for lx, ly in [(10+shake, 47), (18, 49), (26+shake, 47), (62-shake, 47), (70, 49), (78-shake, 47)]:
        fill_rect(img, lx, ly, 6, 3, bp.LEG_DARK)
        fill_rect(img, lx+1, ly, 4, 2, bp.LEG_MID)
    
    # 腹部
    fill_rect(img, 20, 42, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22, 43, 52, 6, bp.BELLY_MID)
    fill_rect(img, 26, 44, 44, 4, bp.BELLY_LIGHT)
    
    # 甲壳（冲锋时压低）
    fill_rect(img, 14, 24, 68, 22, bp.SHELL_DARK)
    fill_rect(img, 16, 25, 64, 20, bp.SHELL_MID)
    fill_rect(img, 20, 26, 56, 18, bp.SHELL_LIGHT)
    fill_rect(img, 26, 27, 44, 16, bp.SHELL_HIGHLIGHT)
    
    # 矿脉晶体（全亮）
    fill_rect(img, 42, 24, 12, 8, bp.CRYSTAL_MID)
    fill_rect(img, 44, 25, 8, 6, bp.CRYSTAL_LIGHT)
    fill_rect(img, 46, 26, 4, 4, bp.CRYSTAL_GLOW)
    
    # 头部（低下）
    fill_rect(img, 34, 16, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36, 17, 24, 10, bp.SHELL_MID)
    fill_rect(img, 38, 18, 20, 8, bp.SHELL_LIGHT)
    # 眼睛（狂暴）
    fill_rect(img, 36, 20, 4, 3, bp.EYE_GLOW)
    fill_rect(img, 37, 21, 2, 1, (255, 255, 200, 255))
    fill_rect(img, 56, 20, 4, 3, bp.EYE_GLOW)
    fill_rect(img, 57, 21, 2, 1, (255, 255, 200, 255))
    
    # 大颚（张开）
    fill_rect(img, 24, 22, 12, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 25, 23, 10, 2, bp.MANDIBLE_MID)
    fill_rect(img, 20, 24, 6, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 18, 25, 3, 1, bp.MANDIBLE_TIP)
    fill_rect(img, 60, 22, 12, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 61, 23, 10, 2, bp.MANDIBLE_MID)
    fill_rect(img, 70, 24, 6, 2, bp.MANDIBLE_LIGHT)
    fill_rect(img, 75, 25, 3, 1, bp.MANDIBLE_TIP)
    
    # 冲锋尘土
    if frame == 1:
        fill_rect(img, 6, 50, 8, 4, (80, 70, 60, 150))
        fill_rect(img, 8, 48, 4, 3, (100, 90, 70, 120))
        fill_rect(img, 80, 50, 8, 4, (80, 70, 60, 150))
    
    return img


def boss_beetle_stunned(frame=0):
    """矿脉甲虫硬直 (2帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    wobble = 2 if frame == 0 else -2
    
    # 腿（松散）
    for lx, ly in [(10+wobble, 48), (18, 50), (26+wobble, 48), (62-wobble, 48), (70, 50), (78-wobble, 48)]:
        fill_rect(img, lx, ly, 6, 3, bp.LEG_DARK)
        fill_rect(img, lx+1, ly, 4, 2, bp.LEG_MID)
    
    # 腹部
    fill_rect(img, 20, 42, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22, 43, 52, 6, bp.BELLY_MID)
    fill_rect(img, 26, 44, 44, 4, bp.BELLY_LIGHT)
    
    # 甲壳
    fill_rect(img, 16+wobble, 20, 64, 24, bp.SHELL_DARK)
    fill_rect(img, 18+wobble, 21, 60, 22, bp.SHELL_MID)
    fill_rect(img, 22+wobble, 22, 52, 20, bp.SHELL_LIGHT)
    
    # 矿脉晶体（暗淡）
    fill_rect(img, 42+wobble, 22, 12, 8, bp.CRYSTAL_DARK)
    fill_rect(img, 44+wobble, 23, 8, 6, bp.CRYSTAL_DARK)
    
    # 头部（歪斜）
    fill_rect(img, 34+wobble, 12, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36+wobble, 13, 24, 10, bp.SHELL_MID)
    # 眼睛（旋转/暗淡）
    fill_rect(img, 36+wobble, 16, 4, 3, (100, 80, 20, 255))
    fill_rect(img, 56+wobble, 16, 4, 3, (100, 80, 20, 255))
    
    # 大颚
    fill_rect(img, 28+wobble, 18, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 60+wobble, 18, 8, 4, bp.MANDIBLE_DARK)
    
    # 星星特效（硬直）
    if frame == 0:
        fill_rect(img, 30, 8, 2, 2, (255, 255, 200, 255))
        fill_rect(img, 60, 6, 2, 2, (255, 255, 200, 255))
    else:
        fill_rect(img, 32, 6, 2, 2, (255, 255, 200, 255))
        fill_rect(img, 58, 8, 2, 2, (255, 255, 200, 255))
    
    return img


def boss_beetle_hurt(frame=0):
    """矿脉甲虫受击 (2帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    knockback = 3 if frame == 0 else 5
    
    # 腿
    for lx, ly in [(10+knockback, 48), (18+knockback, 50), (26+knockback, 48), 
                    (62+knockback, 48), (70+knockback, 50), (78+knockback, 48)]:
        fill_rect(img, lx, ly, 6, 3, bp.LEG_DARK)
    
    # 腹部
    fill_rect(img, 20+knockback, 42, 56, 8, bp.BELLY_DARK)
    fill_rect(img, 22+knockback, 43, 52, 6, bp.BELLY_MID)
    
    # 甲壳
    fill_rect(img, 16+knockback, 20, 64, 24, bp.SHELL_DARK)
    fill_rect(img, 18+knockback, 21, 60, 22, bp.SHELL_MID)
    fill_rect(img, 22+knockback, 22, 52, 20, bp.SHELL_LIGHT)
    
    # 矿脉晶体（碎裂效果）
    fill_rect(img, 42+knockback, 22, 12, 8, bp.CRYSTAL_DARK)
    if frame == 1:
        fill_rect(img, 38+knockback, 20, 4, 4, bp.CRYSTAL_LIGHT)  # 飞出碎片
        fill_rect(img, 56+knockback, 18, 3, 3, bp.CRYSTAL_MID)
    
    # 头部
    fill_rect(img, 34+knockback, 12, 28, 12, bp.SHELL_DARK)
    fill_rect(img, 36+knockback, 13, 24, 10, bp.SHELL_MID)
    # 眼睛（受击闪烁）
    fill_rect(img, 36+knockback, 16, 4, 3, (255, 255, 255, 255) if frame == 0 else bp.EYE_DARK)
    fill_rect(img, 56+knockback, 16, 4, 3, (255, 255, 255, 255) if frame == 0 else bp.EYE_DARK)
    
    # 大颚
    fill_rect(img, 28+knockback, 18, 8, 4, bp.MANDIBLE_DARK)
    fill_rect(img, 60+knockback, 18, 8, 4, bp.MANDIBLE_DARK)
    
    return img


def boss_beetle_death(frame=0):
    """矿脉甲虫死亡 (4帧)"""
    img = new_sprite(96, 64)
    bp = BeetlePalette
    # 逐渐倒下 + 碎片
    fall_offset = frame * 3
    alpha = max(0, 255 - frame * 60)
    
    # 腿（散开）
    for lx, ly in [(10+fall_offset, 48+fall_offset), (18, 52), (26+fall_offset, 50), 
                    (62-fall_offset, 50), (70, 52), (78-fall_offset, 48+fall_offset)]:
        fill_rect(img, lx, ly, 6, 3, (*bp.LEG_DARK[:3], alpha))
    
    # 腹部
    fill_rect(img, 20, 42+fall_offset, 56, 8, (*bp.BELLY_DARK[:3], alpha))
    fill_rect(img, 22, 43+fall_offset, 52, 6, (*bp.BELLY_MID[:3], alpha))
    
    # 甲壳（翻转）
    fill_rect(img, 16, 20+fall_offset, 64, 24, (*bp.SHELL_DARK[:3], alpha))
    fill_rect(img, 18, 21+fall_offset, 60, 22, (*bp.SHELL_MID[:3], alpha))
    
    # 矿脉晶体（碎裂飞散）
    if frame > 0:
        for i in range(frame * 2):
            cx = 30 + i * 8 + rand_offset()
            cy = 10 + i * 4
            fill_rect(img, cx, cy, 3, 3, (*bp.CRYSTAL_GLOW[:3], alpha))
    
    # 头部
    fill_rect(img, 34, 12+fall_offset, 28, 12, (*bp.SHELL_DARK[:3], alpha))
    # 眼睛逐渐暗淡
    fill_rect(img, 36, 16+fall_offset, 4, 3, (*bp.EYE_DARK[:3], alpha))
    fill_rect(img, 56, 16+fall_offset, 4, 3, (*bp.EYE_DARK[:3], alpha))
    
    # 死亡光效
    if frame < 3:
        fill_rect(img, 44, 10+fall_offset, 8, 4, (255, 240, 150, min(255, alpha + 50)))
        fill_rect(img, 46, 8+fall_offset, 4, 6, (255, 255, 200, min(255, alpha)))
    
    return img


def rand_offset():
    import random
    return random.randint(-4, 4)


def training_dummy(frame=0):
    img = new_sprite()
    p = Palette
    shake = 1 if frame == 1 else 0
    
    # 底座
    fill_rect(img, 22+shake, 52, 20, 6, p.WOOD_DARK)
    fill_rect(img, 24+shake, 53, 16, 4, p.WOOD_MID)
    
    # 主干
    fill_rect(img, 28+shake, 16, 8, 36, p.WOOD_DARK)
    fill_rect(img, 29+shake, 17, 6, 34, p.WOOD_MID)
    fill_rect(img, 30+shake, 18, 4, 32, p.WOOD_LIGHT)
    
    # 横梁
    fill_rect(img, 18+shake, 24, 28, 4, p.WOOD_DARK)
    fill_rect(img, 19+shake, 25, 26, 2, p.WOOD_MID)
    fill_rect(img, 20+shake, 25, 24, 1, p.WOOD_LIGHT)
    
    # 头部
    fill_rect(img, 26+shake, 8, 12, 10, p.WOOD_DARK)
    fill_rect(img, 27+shake, 9, 10, 8, p.WOOD_MID)
    fill_rect(img, 28+shake, 10, 8, 6, p.WOOD_LIGHT)
    fill_rect(img, 30+shake, 10, 4, 2, p.WOOD_HIGHLIGHT)
    
    # 靶心
    fill_rect(img, 30+shake, 28, 4, 4, p.ROPE)
    fill_rect(img, 31+shake, 29, 2, 2, (200, 60, 40, 255))
    
    # 绳索
    fill_rect(img, 30+shake, 20, 1, 4, p.ROPE)
    fill_rect(img, 33+shake, 20, 1, 4, p.ROPE)
    
    # 受击特效
    if frame == 1:
        fill_rect(img, 14, 22, 4, 2, p.SPARK_YELLOW)
        fill_rect(img, 38, 26, 3, 2, p.SPARK_ORANGE)
        fill_rect(img, 16, 28, 2, 2, p.SPARK_WHITE)
    
    return img


def create_spritesheet(frames, frame_size=64, cols=4):
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


def create_full_sheet():
    animations = {
        'idle': [warrior_idle(i) for i in range(4)],
        'run': [warrior_run(i) for i in range(4)],
        'attack': [warrior_attack(i) for i in range(4)],
        'guard': [warrior_guard(i) for i in range(2)],
        'jump': [warrior_jump(i) for i in range(2)],
        'hurt': [warrior_hurt(i) for i in range(2)],
        'war_cry': [warrior_skill_war_cry(i) for i in range(2)],
        'earth_shatter': [warrior_skill_earth_shatter(i) for i in range(2)],
    }
    
    total_frames = sum(len(v) for v in animations.values())
    cols = 8
    rows = (total_frames + cols - 1) // cols
    
    full_sheet = Image.new('RGBA', (cols * 64, rows * 64), (0, 0, 0, 0))
    
    frame_idx = 0
    meta = {}
    
    for anim_name, frames in animations.items():
        start_frame = frame_idx
        for frame in frames:
            col = frame_idx % cols
            row = frame_idx // cols
            full_sheet.paste(frame, (col * 64, row * 64))
            frame_idx += 1
        meta[anim_name] = {
            'start_frame': start_frame,
            'frame_count': len(frames),
            'col': start_frame % cols,
            'row': start_frame // cols,
        }
    
    return full_sheet, meta, animations


def main():
    print("=== 《代号：传说》像素精灵图生成器 ===")
    print()
    
    animations = {
        'idle': [warrior_idle(i) for i in range(4)],
        'run': [warrior_run(i) for i in range(4)],
        'attack': [warrior_attack(i) for i in range(4)],
        'guard': [warrior_guard(i) for i in range(2)],
        'jump': [warrior_jump(i) for i in range(2)],
        'hurt': [warrior_hurt(i) for i in range(2)],
        'war_cry': [warrior_skill_war_cry(i) for i in range(2)],
        'earth_shatter': [warrior_skill_earth_shatter(i) for i in range(2)],
    }
    
    player_dir = os.path.join(OUTPUT_DIR, "player")
    enemy_dir = os.path.join(OUTPUT_DIR, "enemy")
    
    for anim_name, frames in animations.items():
        sheet = create_spritesheet(frames, 64, len(frames))
        path = os.path.join(player_dir, f"warrior_{anim_name}_sheet.png")
        sheet.save(path)
        print(f"  保存: warrior_{anim_name}_sheet.png ({sheet.size[0]}x{sheet.size[1]})")
        frames[0].save(os.path.join(player_dir, f"warrior_{anim_name}_64.png"))
    
    full_sheet, meta, _ = create_full_sheet()
    full_path = os.path.join(player_dir, "warrior_full_sheet.png")
    full_sheet.save(full_path)
    print(f"\n  完整精灵图表: warrior_full_sheet.png ({full_sheet.size[0]}x{full_sheet.size[1]})")
    
    meta_path = os.path.join(player_dir, "warrior_sheet_meta.txt")
    with open(meta_path, 'w') as f:
        f.write("# Warrior Sprite Sheet Metadata\n")
        f.write(f"# Sheet size: {full_sheet.size[0]}x{full_sheet.size[1]}\n")
        f.write("# Frame size: 64x64\n\n")
        for name, m in meta.items():
            f.write(f"{name}={m['start_frame']},{m['frame_count']},{m['col']},{m['row']}\n")
    print(f"  元数据: warrior_sheet_meta.txt")
    
    # 训练木桩
    dummy_frames = [training_dummy(i) for i in range(2)]
    dummy_sheet = create_spritesheet(dummy_frames, 64, 2)
    dummy_sheet.save(os.path.join(enemy_dir, "training_dummy_sheet.png"))
    dummy_frames[0].save(os.path.join(enemy_dir, "training_dummy_64.png"))
    print(f"\n  训练木桩: training_dummy_sheet.png (128x64)")
    
    # === 矿脉甲虫 Boss ===
    boss_dir = os.path.join(OUTPUT_DIR, "enemy")
    boss_anims = {
        'idle': [boss_beetle_idle(i) for i in range(4)],
        'walk': [boss_beetle_walk(i) for i in range(4)],
        'attack': [boss_beetle_attack(i) for i in range(4)],
        'charge': [boss_beetle_charge(i) for i in range(2)],
        'stunned': [boss_beetle_stunned(i) for i in range(2)],
        'hurt': [boss_beetle_hurt(i) for i in range(2)],
        'death': [boss_beetle_death(i) for i in range(4)],
    }
    
    for anim_name, frames in boss_anims.items():
        sheet = create_spritesheet(frames, 96, len(frames))
        path = os.path.join(boss_dir, f"boss_beetle_{anim_name}_sheet.png")
        sheet.save(path)
        print(f"  Boss: boss_beetle_{anim_name}_sheet.png ({sheet.size[0]}x{sheet.size[1]})")
        frames[0].save(os.path.join(boss_dir, f"boss_beetle_{anim_name}_64.png"))
    
    # 验证透明度
    print("\n=== 透明度验证 ===")
    for anim_name, frames in animations.items():
        alpha = frames[0].getchannel('A')
        transparent = sum(1 for p in alpha.getdata() if p == 0)
        total = alpha.width * alpha.height
        pct = transparent / total * 100
        print(f"  {anim_name}: 透明度={pct:.1f}%")
    
    alpha = full_sheet.getchannel('A')
    transparent = sum(1 for p in alpha.getdata() if p == 0)
    total = alpha.width * alpha.height
    print(f"\n  完整图表: 透明度={transparent/total*100:.1f}%")
    
    print("\n=== 生成完成! ===")


if __name__ == '__main__':
    main()
