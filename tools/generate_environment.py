#!/usr/bin/env python3
"""
《代号：传说》环境装饰精灵生成器
- 高品质像素风环境装饰：火炬、水晶、钟乳石、蛛网、矿石、蘑菇
- 视差背景层：远山、中景建筑、近景细节
- 地面瓦片：带纹理和边缘的地面/平台/墙壁
- UI元素：血条框、怒气条框、图标等
"""

from PIL import Image, ImageDraw
import os
import math

OUTPUT_DIR = "/home/z/my-project/godot/legend/assets/sprites"


def new_sprite(w=64, h=64):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def fill_rect(img, x, y, w, h, color):
    d = img.load()
    for py in range(y, y + h):
        for px in range(x, x + w):
            if 0 <= px < img.width and 0 <= py < img.height:
                d[px, py] = color


def draw_circle(img, cx, cy, r, color):
    """绘制填充圆"""
    d = img.load()
    for py in range(cy - r, cy + r + 1):
        for px in range(cx - r, cx + r + 1):
            if 0 <= px < img.width and 0 <= py < img.height:
                if (px - cx) ** 2 + (py - cy) ** 2 <= r * r:
                    d[px, py] = color


def draw_circle_outline(img, cx, cy, r, color):
    """绘制圆轮廓"""
    d = img.load()
    for angle in range(0, 360):
        px = int(cx + r * math.cos(math.radians(angle)))
        py = int(cy + r * math.sin(math.radians(angle)))
        if 0 <= px < img.width and 0 <= py < img.height:
            d[px, py] = color


# ============================================================
# 环境装饰 - 矿井主题
# ============================================================

class EnvPalette:
    """矿井环境调色板"""
    # 石头
    STONE_DARK = (35, 30, 40, 255)
    STONE_MID = (55, 48, 58, 255)
    STONE_LIGHT = (78, 68, 80, 255)
    STONE_HIGHLIGHT = (100, 88, 105, 255)
    # 苔藓
    MOSS_DARK = (30, 50, 25, 255)
    MOSS_MID = (45, 72, 35, 255)
    MOSS_LIGHT = (60, 95, 48, 255)
    MOSS_BRIGHT = (80, 120, 55, 255)
    # 火
    FIRE_CORE = (255, 240, 180, 255)
    FIRE_BRIGHT = (255, 200, 80, 255)
    FIRE_MID = (255, 140, 30, 255)
    FIRE_DARK = (220, 80, 15, 255)
    FIRE_TIP = (180, 50, 10, 255)
    # 火把
    TORCH_WOOD = (90, 55, 25, 255)
    TORCH_DARK = (60, 35, 15, 255)
    TORCH_WRAP = (120, 85, 35, 255)
    # 水晶
    CRYSTAL_BLUE_DARK = (40, 80, 130, 255)
    CRYSTAL_BLUE_MID = (70, 130, 200, 255)
    CRYSTAL_BLUE_LIGHT = (110, 180, 240, 255)
    CRYSTAL_BLUE_GLOW = (160, 220, 255, 255)
    CRYSTAL_PURPLE_DARK = (80, 40, 120, 255)
    CRYSTAL_PURPLE_MID = (120, 70, 180, 255)
    CRYSTAL_PURPLE_LIGHT = (160, 110, 220, 255)
    CRYSTAL_PURPLE_GLOW = (200, 160, 255, 255)
    # 钟乳石
    STAL_DARK = (50, 45, 55, 255)
    STAL_MID = (70, 62, 75, 255)
    STAL_LIGHT = (90, 80, 98, 255)
    STAL_TIP = (120, 108, 125, 255)
    STAL_WET = (140, 155, 170, 255)
    # 蛛网
    WEB_COLOR = (200, 200, 210, 120)
    WEB_THICK = (180, 180, 195, 160)
    # 矿石
    ORE_DARK = (80, 65, 45, 255)
    ORE_MID = (120, 95, 55, 255)
    ORE_LIGHT = (165, 130, 70, 255)
    ORE_GLOW = (220, 190, 100, 255)
    ORE_CRYSTAL = (255, 230, 130, 255)
    # 蘑菇
    MUSH_CAP_DARK = (90, 30, 40, 255)
    MUSH_CAP_MID = (140, 50, 60, 255)
    MUSH_CAP_LIGHT = (180, 80, 90, 255)
    MUSH_SPOT = (220, 200, 180, 255)
    MUSH_STEM = (180, 170, 150, 255)
    MUSH_STEM_DARK = (140, 130, 110, 255)
    # 发光蘑菇
    GLOW_CAP_DARK = (30, 80, 100, 255)
    GLOW_CAP_MID = (50, 130, 160, 255)
    GLOW_CAP_LIGHT = (80, 180, 210, 255)
    GLOW_GLOW = (120, 220, 255, 200)
    GLOW_STEM = (160, 180, 190, 255)


def env_torch(frame=0):
    """火炬 - 带火焰动画 32x48"""
    img = new_sprite(32, 48)
    p = EnvPalette
    
    # 墙壁支架
    fill_rect(img, 10, 20, 12, 3, p.STONE_MID)
    fill_rect(img, 11, 21, 10, 1, p.STONE_LIGHT)
    
    # 火把杆
    fill_rect(img, 14, 18, 4, 20, p.TORCH_WOOD)
    fill_rect(img, 15, 18, 2, 20, p.TORCH_DARK)
    # 包裹布
    fill_rect(img, 13, 18, 6, 5, p.TORCH_WRAP)
    fill_rect(img, 14, 19, 4, 3, p.TORCH_WOOD)
    
    # 火焰 - 3帧动画
    flicker = [0, -1, 1][frame % 3]
    sway = [0, 1, -1][frame % 3]
    
    # 火焰主体（底部宽，顶部尖）
    fill_rect(img, 12 + sway, 10 + flicker, 8, 8, p.FIRE_DARK)
    fill_rect(img, 13 + sway, 8 + flicker, 6, 6, p.FIRE_MID)
    fill_rect(img, 14 + sway, 6 + flicker, 4, 5, p.FIRE_BRIGHT)
    fill_rect(img, 15 + sway, 4 + flicker, 2, 4, p.FIRE_CORE)
    fill_rect(img, 15, 3 + flicker, 2, 2, p.FIRE_CORE)
    
    # 火花
    if frame % 3 == 0:
        fill_rect(img, 10 + sway, 6 + flicker, 2, 1, p.FIRE_BRIGHT)
        fill_rect(img, 20 + sway, 8 + flicker, 2, 1, p.FIRE_BRIGHT)
    elif frame % 3 == 1:
        fill_rect(img, 11 + sway, 4 + flicker, 1, 1, p.FIRE_BRIGHT)
    
    # 光晕效果
    fill_rect(img, 8, 14, 16, 4, (255, 200, 80, 30))
    fill_rect(img, 10, 12, 12, 2, (255, 180, 60, 20))
    
    return img


def env_crystal_cluster(frame=0):
    """水晶簇 - 32x32，带微光"""
    img = new_sprite(32, 32)
    p = EnvPalette
    
    # 底座岩石
    fill_rect(img, 4, 22, 24, 8, p.STONE_DARK)
    fill_rect(img, 6, 23, 20, 6, p.STONE_MID)
    fill_rect(img, 8, 24, 16, 4, p.STONE_LIGHT)
    
    # 水晶1（左，小）
    fill_rect(img, 8, 10, 4, 12, p.CRYSTAL_BLUE_DARK)
    fill_rect(img, 9, 8, 2, 10, p.CRYSTAL_BLUE_MID)
    fill_rect(img, 9, 6, 2, 4, p.CRYSTAL_BLUE_LIGHT)
    fill_rect(img, 10, 5, 1, 2, p.CRYSTAL_BLUE_GLOW)
    
    # 水晶2（中，大）
    fill_rect(img, 14, 6, 6, 16, p.CRYSTAL_PURPLE_DARK)
    fill_rect(img, 15, 4, 4, 14, p.CRYSTAL_PURPLE_MID)
    fill_rect(img, 16, 2, 2, 10, p.CRYSTAL_PURPLE_LIGHT)
    fill_rect(img, 16, 1, 2, 3, p.CRYSTAL_PURPLE_GLOW)
    
    # 水晶3（右，中）
    fill_rect(img, 21, 12, 4, 10, p.CRYSTAL_BLUE_DARK)
    fill_rect(img, 22, 10, 2, 8, p.CRYSTAL_BLUE_MID)
    fill_rect(img, 22, 8, 2, 4, p.CRYSTAL_BLUE_LIGHT)
    
    # 发光闪烁
    if frame % 4 == 0:
        fill_rect(img, 15, 0, 4, 2, (200, 160, 255, 60))
        fill_rect(img, 8, 4, 3, 2, (160, 220, 255, 40))
    
    return img


def env_stalactite_small():
    """小钟乳石 - 16x32"""
    img = new_sprite(16, 32)
    p = EnvPalette
    
    fill_rect(img, 4, 0, 8, 4, p.STAL_DARK)
    fill_rect(img, 5, 4, 6, 6, p.STAL_MID)
    fill_rect(img, 6, 10, 4, 8, p.STAL_MID)
    fill_rect(img, 7, 18, 3, 6, p.STAL_LIGHT)
    fill_rect(img, 7, 24, 2, 4, p.STAL_TIP)
    fill_rect(img, 7, 28, 1, 2, p.STAL_WET)
    
    # 水滴
    fill_rect(img, 7, 30, 1, 2, (140, 170, 200, 180))
    
    return img


def env_stalactite_large():
    """大钟乳石 - 24x48"""
    img = new_sprite(24, 48)
    p = EnvPalette
    
    fill_rect(img, 4, 0, 16, 6, p.STAL_DARK)
    fill_rect(img, 6, 6, 12, 10, p.STAL_MID)
    fill_rect(img, 7, 16, 10, 10, p.STAL_MID)
    fill_rect(img, 8, 26, 8, 8, p.STAL_LIGHT)
    fill_rect(img, 9, 34, 6, 6, p.STAL_TIP)
    fill_rect(img, 10, 40, 4, 4, p.STAL_TIP)
    fill_rect(img, 10, 44, 2, 2, p.STAL_WET)
    
    # 湿润反光
    fill_rect(img, 8, 10, 1, 4, p.STAL_WET)
    fill_rect(img, 14, 20, 1, 3, p.STAL_WET)
    
    return img


def env_cobweb():
    """蛛网 - 32x32"""
    img = new_sprite(32, 32)
    p = EnvPalette
    
    # 放射状丝线
    for angle in range(0, 360, 45):
        for r in range(2, 15):
            px = int(16 + r * math.cos(math.radians(angle)))
            py = int(16 + r * math.sin(math.radians(angle)))
            if 0 <= px < 32 and 0 <= py < 32:
                alpha = max(60, 160 - r * 8)
                img.putpixel((px, py), (200, 200, 210, alpha))
    
    # 同心环
    for r in [4, 7, 10, 13]:
        for angle in range(0, 360, 2):
            px = int(16 + r * math.cos(math.radians(angle)))
            py = int(16 + r * math.sin(math.radians(angle)))
            if 0 <= px < 32 and 0 <= py < 32:
                alpha = max(40, 130 - r * 6)
                img.putpixel((px, py), (200, 200, 210, alpha))
    
    # 中心蜘蛛
    fill_rect(img, 15, 15, 2, 2, (50, 45, 55, 200))
    fill_rect(img, 14, 16, 4, 1, (50, 45, 55, 160))
    
    return img


def env_ore_deposit(frame=0):
    """矿脉沉积 - 32x24"""
    img = new_sprite(32, 24)
    p = EnvPalette
    
    # 岩石基座
    fill_rect(img, 0, 8, 32, 16, p.STONE_DARK)
    fill_rect(img, 2, 10, 28, 12, p.STONE_MID)
    fill_rect(img, 4, 12, 24, 8, p.STONE_LIGHT)
    
    # 矿脉（金色纹理穿过岩石）
    fill_rect(img, 6, 10, 4, 6, p.ORE_DARK)
    fill_rect(img, 7, 11, 2, 4, p.ORE_MID)
    fill_rect(img, 14, 8, 6, 5, p.ORE_DARK)
    fill_rect(img, 15, 9, 4, 3, p.ORE_MID)
    fill_rect(img, 16, 9, 2, 2, p.ORE_LIGHT)
    fill_rect(img, 22, 12, 4, 4, p.ORE_DARK)
    fill_rect(img, 23, 13, 2, 2, p.ORE_MID)
    
    # 闪光晶体
    fill_rect(img, 16, 7, 2, 2, p.ORE_CRYSTAL)
    fill_rect(img, 8, 9, 1, 1, p.ORE_CRYSTAL)
    
    # 闪烁效果
    if frame % 6 < 3:
        fill_rect(img, 16, 6, 1, 1, (255, 255, 220, 200))
    
    return img


def env_mushroom_red():
    """红色毒蘑菇 - 16x16"""
    img = new_sprite(16, 16)
    p = EnvPalette
    
    # 菌柄
    fill_rect(img, 6, 8, 4, 6, p.MUSH_STEM)
    fill_rect(img, 7, 8, 2, 6, p.MUSH_STEM_DARK)
    
    # 菌盖
    draw_circle(img, 8, 6, 6, p.MUSH_CAP_DARK)
    draw_circle(img, 8, 6, 5, p.MUSH_CAP_MID)
    draw_circle(img, 8, 5, 3, p.MUSH_CAP_LIGHT)
    
    # 白色斑点
    fill_rect(img, 5, 4, 2, 2, p.MUSH_SPOT)
    fill_rect(img, 10, 5, 2, 2, p.MUSH_SPOT)
    fill_rect(img, 7, 2, 2, 2, p.MUSH_SPOT)
    
    return img


def env_mushroom_glow(frame=0):
    """发光蘑菇 - 16x16，带光晕"""
    img = new_sprite(16, 16)
    p = EnvPalette
    
    # 菌柄
    fill_rect(img, 6, 8, 4, 6, p.GLOW_STEM)
    fill_rect(img, 7, 8, 2, 6, (130, 150, 160, 255))
    
    # 菌盖
    draw_circle(img, 8, 6, 5, p.GLOW_CAP_DARK)
    draw_circle(img, 8, 6, 4, p.GLOW_CAP_MID)
    draw_circle(img, 8, 5, 2, p.GLOW_CAP_LIGHT)
    
    # 光晕
    glow_alpha = 80 + (20 if frame % 4 < 2 else -20)
    for r in range(7, 10):
        for angle in range(0, 360, 8):
            px = int(8 + r * math.cos(math.radians(angle)))
            py = int(6 + r * math.sin(math.radians(angle)))
            if 0 <= px < 16 and 0 <= py < 16:
                a = max(20, glow_alpha - r * 10)
                img.putpixel((px, py), (120, 220, 255, a))
    
    return img


def env_chain():
    """悬挂锁链 - 8x48"""
    img = new_sprite(8, 48)
    
    for i in range(6):
        y = i * 8
        # 链环
        fill_rect(img, 2, y, 4, 2, (80, 80, 90, 255))
        fill_rect(img, 3, y, 2, 2, (110, 110, 120, 255))
        fill_rect(img, 2, y + 2, 4, 2, (70, 70, 80, 255))
        fill_rect(img, 3, y + 2, 2, 2, (100, 100, 110, 255))
        fill_rect(img, 1, y + 4, 6, 2, (80, 80, 90, 255))
        fill_rect(img, 2, y + 4, 4, 2, (110, 110, 120, 255))
    
    return img


# ============================================================
# 视差背景层
# ============================================================

class BgPalette:
    """背景调色板"""
    # 矿井远景
    FAR_MOUNTAIN = (18, 16, 25, 255)
    FAR_MID = (25, 22, 35, 255)
    # 矿井中景
    MID_STRUCTURE = (30, 28, 40, 255)
    MID_DETAIL = (40, 36, 52, 255)
    # 矿井近景
    NEAR_PILLAR = (50, 45, 60, 255)
    NEAR_DETAIL = (65, 58, 78, 255)
    # 熔岩远景
    LAVA_FAR = (40, 15, 10, 255)
    LAVA_MID = (60, 20, 12, 255)
    LAVA_GLOW = (120, 40, 15, 100)


def parallax_mine_far():
    """矿井远景层 - 远山/洞穴轮廓 640x120"""
    img = Image.new('RGBA', (640, 120), (0, 0, 0, 0))
    p = BgPalette
    
    # 远处山脉轮廓
    heights = []
    for x in range(640):
        h = 40 + 15 * math.sin(x * 0.01) + 8 * math.sin(x * 0.03) + 5 * math.sin(x * 0.07)
        heights.append(int(h))
    
    for x in range(640):
        h = heights[x]
        for y in range(h, 120):
            color = p.FAR_MOUNTAIN if y < h + 5 else p.FAR_MID
            img.putpixel((x, y), color)
    
    # 远处钟乳石
    for cx in [50, 180, 320, 450, 580]:
        for dy in range(20):
            w = max(1, 5 - dy // 5)
            for dx in range(-w, w + 1):
                px = cx + dx
                if 0 <= px < 640:
                    img.putpixel((px, dy), p.FAR_MOUNTAIN)
    
    return img


def parallax_mine_mid():
    """矿井中景层 - 洞穴结构/柱子 640x160"""
    img = Image.new('RGBA', (640, 160), (0, 0, 0, 0))
    p = BgPalette
    
    # 天花板轮廓
    for x in range(640):
        ceil_h = 10 + 5 * math.sin(x * 0.02) + 3 * math.sin(x * 0.05)
        for y in range(int(ceil_h)):
            img.putpixel((x, y), p.MID_STRUCTURE)
    
    # 柱子
    for px in [80, 240, 400, 560]:
        # 柱身
        for y in range(20, 160):
            for dx in range(-6, 7):
                x = px + dx
                if 0 <= x < 640:
                    if abs(dx) <= 3:
                        img.putpixel((x, y), p.MID_DETAIL)
                    else:
                        img.putpixel((x, y), p.MID_STRUCTURE)
        # 柱顶
        for dx in range(-10, 11):
            x = px + dx
            if 0 <= x < 640:
                img.putpixel((x, 18), p.MID_DETAIL)
                img.putpixel((x, 19), p.MID_DETAIL)
        # 柱底
        for dx in range(-8, 9):
            x = px + dx
            if 0 <= x < 640:
                img.putpixel((x, 155), p.MID_DETAIL)
                img.putpixel((x, 156), p.MID_DETAIL)
    
    # 钟乳石
    for cx in [30, 130, 190, 310, 370, 480, 530, 620]:
        length = 10 + (cx * 7) % 15
        for dy in range(length):
            w = max(0, 3 - dy // 5)
            for dx in range(-w, w + 1):
                x = cx + dx
                if 0 <= x < 640:
                    img.putpixel((x, dy + int(8 + 3 * math.sin(cx * 0.1))), p.MID_STRUCTURE)
    
    return img


def parallax_lava_far():
    """熔岩区域远景 640x120"""
    img = Image.new('RGBA', (640, 120), (0, 0, 0, 0))
    p = BgPalette
    
    # 底部熔岩发光
    for x in range(640):
        for y in range(80, 120):
            dist = y - 80
            alpha = min(255, dist * 6)
            r = min(255, 120 + dist * 3)
            g = min(255, 30 + dist)
            b = 10
            img.putpixel((x, y), (r, g, b, alpha))
    
    # 远处山脉
    for x in range(640):
        h = 50 + 10 * math.sin(x * 0.015) + 5 * math.sin(x * 0.04)
        for y in range(int(h), 80):
            img.putpixel((x, y), p.LAVA_FAR)
    
    # 熔岩光柱
    for lx in [100, 300, 500]:
        for y in range(60, 120):
            for dx in range(-4, 5):
                x = lx + dx
                if 0 <= x < 640:
                    alpha = max(10, 60 - abs(dx) * 12 - (y - 60) // 2)
                    img.putpixel((x, y), (255, 120, 30, alpha))
    
    return img


# ============================================================
# 地面瓦片
# ============================================================

def tile_ground_32():
    """地面瓦片 - 32x32 带纹理"""
    img = new_sprite(32, 32)
    
    # 顶部边缘（亮）
    fill_rect(img, 0, 0, 32, 2, (90, 82, 98, 255))
    fill_rect(img, 0, 0, 32, 1, (110, 100, 118, 255))
    
    # 主体
    fill_rect(img, 0, 2, 32, 28, (55, 48, 62, 255))
    fill_rect(img, 0, 2, 32, 4, (65, 58, 72, 255))
    
    # 石纹
    for y in range(4, 30, 6):
        fill_rect(img, 0, y, 32, 1, (60, 53, 68, 255))
    for x in range(8, 32, 12):
        for y in range(4, 30, 6):
            fill_rect(img, x, y, 1, 5, (50, 43, 56, 255))
    
    # 裂缝装饰
    fill_rect(img, 5, 8, 3, 1, (45, 38, 50, 255))
    fill_rect(img, 20, 14, 5, 1, (45, 38, 50, 255))
    fill_rect(img, 12, 22, 4, 1, (45, 38, 50, 255))
    
    return img


def tile_platform_32():
    """平台瓦片 - 32x8 带纹理和支撑"""
    img = new_sprite(32, 16)
    
    # 平台顶面
    fill_rect(img, 0, 0, 32, 3, (90, 82, 98, 255))
    fill_rect(img, 1, 0, 30, 2, (110, 100, 118, 255))
    
    # 平台底面
    fill_rect(img, 0, 3, 32, 3, (65, 58, 72, 255))
    fill_rect(img, 0, 3, 32, 1, (75, 68, 82, 255))
    
    # 支撑柱（薄）
    fill_rect(img, 3, 6, 3, 10, (55, 48, 62, 255))
    fill_rect(img, 4, 6, 1, 10, (65, 58, 72, 255))
    fill_rect(img, 26, 6, 3, 10, (55, 48, 62, 255))
    fill_rect(img, 27, 6, 1, 10, (65, 58, 72, 255))
    
    # 边缘细节
    fill_rect(img, 0, 0, 1, 3, (120, 110, 128, 255))
    fill_rect(img, 31, 0, 1, 3, (120, 110, 128, 255))
    
    return img


def tile_ground_lava_32():
    """熔岩地面瓦片 - 32x32"""
    img = new_sprite(32, 32)
    
    # 顶部边缘
    fill_rect(img, 0, 0, 32, 2, (100, 60, 40, 255))
    fill_rect(img, 0, 0, 32, 1, (130, 75, 45, 255))
    
    # 主体
    fill_rect(img, 0, 2, 32, 28, (65, 35, 25, 255))
    
    # 纹理
    for y in range(4, 30, 5):
        fill_rect(img, 0, y, 32, 1, (70, 38, 28, 255))
    
    # 熔岩裂缝
    fill_rect(img, 6, 6, 2, 8, (180, 60, 15, 200))
    fill_rect(img, 7, 7, 1, 6, (255, 120, 30, 150))
    fill_rect(img, 18, 10, 2, 6, (180, 60, 15, 200))
    fill_rect(img, 19, 11, 1, 4, (255, 120, 30, 150))
    
    return img


# ============================================================
# UI 元素
# ============================================================

def ui_hp_bar_frame():
    """HP条边框 - 130x12"""
    img = new_sprite(130, 12)
    
    # 外框
    fill_rect(img, 0, 0, 130, 12, (40, 35, 45, 255))
    # 内框
    fill_rect(img, 1, 1, 128, 10, (25, 20, 30, 255))
    # 顶部高光
    fill_rect(img, 1, 1, 128, 1, (50, 45, 58, 255))
    # 底部阴影
    fill_rect(img, 1, 10, 128, 1, (20, 15, 25, 255))
    # 刻度线
    for x in [31, 62, 93]:
        fill_rect(img, x, 1, 1, 10, (40, 35, 45, 200))
    
    return img


def ui_rage_bar_frame():
    """怒气条边框 - 130x10"""
    img = new_sprite(130, 10)
    
    fill_rect(img, 0, 0, 130, 10, (40, 35, 45, 255))
    fill_rect(img, 1, 1, 128, 8, (25, 20, 30, 255))
    fill_rect(img, 1, 1, 128, 1, (50, 45, 58, 255))
    fill_rect(img, 1, 8, 128, 1, (20, 15, 25, 255))
    # 50%标记
    fill_rect(img, 64, 1, 1, 8, (50, 40, 30, 200))
    
    return img


def ui_boss_hp_frame():
    """Boss HP条边框 - 304x14"""
    img = new_sprite(304, 14)
    
    fill_rect(img, 0, 0, 304, 14, (40, 35, 45, 255))
    fill_rect(img, 1, 1, 302, 12, (25, 20, 30, 255))
    fill_rect(img, 1, 1, 302, 1, (55, 45, 60, 255))
    fill_rect(img, 1, 12, 302, 1, (20, 15, 25, 255))
    # 刻度
    for x in [76, 152, 228]:
        fill_rect(img, x, 1, 1, 12, (40, 35, 45, 180))
    
    # 两端装饰
    fill_rect(img, 0, 0, 4, 14, (60, 50, 65, 255))
    fill_rect(img, 300, 0, 4, 14, (60, 50, 65, 255))
    
    return img


def ui_skill_icon_attack():
    """攻击技能图标 - 24x24"""
    img = new_sprite(24, 24)
    
    # 背景
    fill_rect(img, 0, 0, 24, 24, (40, 15, 15, 255))
    fill_rect(img, 1, 1, 22, 22, (60, 20, 20, 255))
    
    # 剑形图标
    fill_rect(img, 11, 3, 2, 12, (220, 200, 160, 255))
    fill_rect(img, 10, 3, 1, 2, (180, 160, 120, 255))
    fill_rect(img, 13, 3, 1, 2, (180, 160, 120, 255))
    fill_rect(img, 8, 15, 8, 2, (160, 130, 80, 255))
    fill_rect(img, 7, 17, 10, 2, (130, 100, 60, 255))
    
    # 高光
    fill_rect(img, 11, 4, 1, 8, (255, 240, 200, 255))
    
    return img


def ui_skill_icon_defense():
    """防御技能图标 - 24x24"""
    img = new_sprite(24, 24)
    
    fill_rect(img, 0, 0, 24, 24, (15, 25, 50, 255))
    fill_rect(img, 1, 1, 22, 22, (20, 40, 70, 255))
    
    # 盾形图标
    for y in range(4, 18):
        w = int(6 * math.sin((y - 4) / 14.0 * math.pi))
        for dx in range(-w, w + 1):
            px = 12 + dx
            if 0 <= px < 24:
                img.putpixel((px, y), (60, 120, 200, 255))
    # 盾高光
    fill_rect(img, 10, 6, 4, 6, (100, 160, 230, 255))
    fill_rect(img, 11, 7, 2, 4, (140, 190, 240, 255))
    
    return img


def ui_skill_icon_rage():
    """怒气技能图标 - 24x24"""
    img = new_sprite(24, 24)
    
    fill_rect(img, 0, 0, 24, 24, (40, 30, 10, 255))
    fill_rect(img, 1, 1, 22, 22, (65, 45, 15, 255))
    
    # 火焰图标
    fill_rect(img, 9, 12, 6, 6, (200, 80, 15, 255))
    fill_rect(img, 10, 8, 4, 8, (255, 150, 30, 255))
    fill_rect(img, 11, 5, 2, 8, (255, 220, 100, 255))
    fill_rect(img, 10, 4, 4, 3, (255, 240, 180, 255))
    
    return img


def ui_panel_frame(w=280, h=200):
    """通用面板边框 - 带装饰角"""
    img = new_sprite(w, h)
    
    # 外框
    fill_rect(img, 0, 0, w, h, (80, 65, 50, 255))
    # 内部
    fill_rect(img, 2, 2, w - 4, h - 4, (15, 12, 22, 255))
    # 内边高光
    fill_rect(img, 2, 2, w - 4, 1, (30, 25, 40, 255))
    fill_rect(img, 2, 2, 1, h - 4, (30, 25, 40, 255))
    # 外边阴影
    fill_rect(img, 2, h - 3, w - 4, 1, (10, 8, 15, 255))
    fill_rect(img, w - 3, 2, 1, h - 4, (10, 8, 15, 255))
    
    # 角装饰
    for corner in [(2, 2), (w - 5, 2), (2, h - 5), (w - 5, h - 5)]:
        fill_rect(img, corner[0], corner[1], 3, 3, (120, 95, 60, 255))
    
    return img


def ui_cursor_8():
    """菜单光标 - 8x8 箭头"""
    img = new_sprite(8, 8)
    
    # 箭头形状
    fill_rect(img, 0, 1, 3, 2, (240, 200, 80, 255))
    fill_rect(img, 1, 3, 3, 2, (240, 200, 80, 255))
    fill_rect(img, 2, 5, 2, 2, (240, 200, 80, 200))
    
    # 高光
    fill_rect(img, 0, 1, 2, 1, (255, 230, 130, 255))
    
    return img


# ============================================================
# 角色阴影
# ============================================================

def shadow_ellipse():
    """角色脚底阴影 - 32x8 椭圆"""
    img = new_sprite(32, 8)
    
    for x in range(32):
        for y in range(8):
            dx = (x - 16) / 16.0
            dy = (y - 4) / 4.0
            if dx * dx + dy * dy <= 1.0:
                dist = dx * dx + dy * dy
                alpha = int(60 * (1.0 - dist))
                img.putpixel((x, y), (0, 0, 0, alpha))
    
    return img


# ============================================================
# 生成所有精灵
# ============================================================

def main():
    print("=== 《代号：传说》环境装饰精灵生成器 ===")
    print()
    
    env_dir = os.path.join(OUTPUT_DIR, "environment")
    os.makedirs(env_dir, exist_ok=True)
    
    bg_dir = os.path.join(OUTPUT_DIR, "background")
    os.makedirs(bg_dir, exist_ok=True)
    
    tile_dir = os.path.join(OUTPUT_DIR, "tiles")
    os.makedirs(tile_dir, exist_ok=True)
    
    ui_dir = os.path.join(OUTPUT_DIR, "ui")
    os.makedirs(ui_dir, exist_ok=True)
    
    common_dir = os.path.join(OUTPUT_DIR, "common")
    os.makedirs(common_dir, exist_ok=True)
    
    # === 环境装饰 ===
    print("生成环境装饰精灵...")
    
    # 火炬（3帧动画）
    torch_frames = [env_torch(i) for i in range(3)]
    for i, frame in enumerate(torch_frames):
        frame.save(os.path.join(env_dir, f"torch_{i}.png"))
    sheet = Image.new('RGBA', (96, 48), (0, 0, 0, 0))
    for i, frame in enumerate(torch_frames):
        sheet.paste(frame, (i * 32, 0))
    sheet.save(os.path.join(env_dir, "torch_sheet.png"))
    
    # 水晶簇（4帧动画）
    crystal_frames = [env_crystal_cluster(i) for i in range(4)]
    for i, frame in enumerate(crystal_frames):
        frame.save(os.path.join(env_dir, f"crystal_cluster_{i}.png"))
    sheet = Image.new('RGBA', (128, 32), (0, 0, 0, 0))
    for i, frame in enumerate(crystal_frames):
        sheet.paste(frame, (i * 32, 0))
    sheet.save(os.path.join(env_dir, "crystal_cluster_sheet.png"))
    
    # 钟乳石
    env_stalactite_small().save(os.path.join(env_dir, "stalactite_small.png"))
    env_stalactite_large().save(os.path.join(env_dir, "stalactite_large.png"))
    
    # 蛛网
    env_cobweb().save(os.path.join(env_dir, "cobweb.png"))
    
    # 矿脉（4帧动画）
    ore_frames = [env_ore_deposit(i) for i in range(4)]
    for i, frame in enumerate(ore_frames):
        frame.save(os.path.join(env_dir, f"ore_deposit_{i}.png"))
    sheet = Image.new('RGBA', (128, 24), (0, 0, 0, 0))
    for i, frame in enumerate(ore_frames):
        sheet.paste(frame, (i * 32, 0))
    sheet.save(os.path.join(env_dir, "ore_deposit_sheet.png"))
    
    # 蘑菇
    env_mushroom_red().save(os.path.join(env_dir, "mushroom_red.png"))
    glow_frames = [env_mushroom_glow(i) for i in range(4)]
    sheet = Image.new('RGBA', (64, 16), (0, 0, 0, 0))
    for i, frame in enumerate(glow_frames):
        sheet.paste(frame, (i * 16, 0))
    sheet.save(os.path.join(env_dir, "mushroom_glow_sheet.png"))
    
    # 锁链
    env_chain().save(os.path.join(env_dir, "chain.png"))
    
    # === 视差背景 ===
    print("生成视差背景层...")
    parallax_mine_far().save(os.path.join(bg_dir, "parallax_mine_far.png"))
    parallax_mine_mid().save(os.path.join(bg_dir, "parallax_mine_mid.png"))
    parallax_lava_far().save(os.path.join(bg_dir, "parallax_lava_far.png"))
    
    # === 地面瓦片 ===
    print("生成地面瓦片...")
    tile_ground_32().save(os.path.join(tile_dir, "ground_stone_32.png"))
    tile_platform_32().save(os.path.join(tile_dir, "platform_stone_32.png"))
    tile_ground_lava_32().save(os.path.join(tile_dir, "ground_lava_32.png"))
    
    # === UI元素 ===
    print("生成UI元素精灵...")
    ui_hp_bar_frame().save(os.path.join(ui_dir, "hp_bar_frame.png"))
    ui_rage_bar_frame().save(os.path.join(ui_dir, "rage_bar_frame.png"))
    ui_boss_hp_frame().save(os.path.join(ui_dir, "boss_hp_frame.png"))
    ui_skill_icon_attack().save(os.path.join(ui_dir, "skill_icon_attack.png"))
    ui_skill_icon_defense().save(os.path.join(ui_dir, "skill_icon_defense.png"))
    ui_skill_icon_rage().save(os.path.join(ui_dir, "skill_icon_rage.png"))
    ui_panel_frame(280, 200).save(os.path.join(ui_dir, "panel_frame_280x200.png"))
    ui_panel_frame(440, 290).save(os.path.join(ui_dir, "panel_frame_440x290.png"))
    ui_cursor_8().save(os.path.join(ui_dir, "cursor_arrow.png"))
    
    # === 通用 ===
    print("生成通用精灵...")
    shadow_ellipse().save(os.path.join(common_dir, "shadow_ellipse.png"))
    
    print()
    print("所有环境装饰精灵生成完成！")
    print(f"输出目录: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
