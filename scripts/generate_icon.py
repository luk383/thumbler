#!/usr/bin/env python3
"""
Generate WAJE app icon — W⚡A replicating the WAJE logo style.
W = blue gradient | ⚡ = orange bold | A = orange gradient
Dark navy background.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# ── Brand colors ──────────────────────────────────────────────────────────
BG_DARK   = (7, 11, 18)          # #070B12
NAVY      = (11, 31, 58)         # #0B1F3A

# Blue gradient (W) — matches logo W
BLUE_TOP  = (30, 100, 220)       # #1E64DC  lighter
BLUE_BOT  = (10, 45, 130)        # #0A2D82  darker

# Orange gradient (A and bolt) — matches logo
ORANGE_T  = (255, 175, 30)       # #FFAF1E  gold/top
ORANGE_B  = (255, 80, 0)         # #FF5000  deep orange/bottom

FONT_PATH  = "/Library/Fonts/Impact.ttf"
FONT_INDEX = 0   # Impact (single font, condensed heavy)


# ── Helpers ───────────────────────────────────────────────────────────────

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_bg(canvas_size):
    """Navy → dark radial gradient background."""
    img = Image.new('RGB', (canvas_size, canvas_size), BG_DARK)
    draw = ImageDraw.Draw(img)
    steps = 35
    for i in range(steps, -1, -1):
        t = i / steps
        c = lerp_color(NAVY, BG_DARK, 1 - t)
        pad = int(canvas_size * 0.45 * t)
        draw.ellipse([pad, pad, canvas_size - pad, canvas_size - pad], fill=c)
    return img


def gradient_fill(width, height, top_color, bot_color):
    """Return an RGB image with a vertical gradient."""
    g = Image.new('RGB', (width, height))
    gd = ImageDraw.Draw(g)
    for y in range(height):
        t = y / max(height - 1, 1)
        c = lerp_color(top_color, bot_color, t)
        gd.line([(0, y), (width, y)], fill=c)
    return g


def render_text_with_gradient(canvas, font, text, x, y, top_color, bot_color):
    """
    Draw `text` at (x, y) on `canvas` with a vertical gradient fill.
    Uses text as a mask, pastes gradient through it.
    """
    # Get bounding box
    bb = font.getbbox(text)
    tw = bb[2] - bb[0]
    th = bb[3] - bb[1]

    # 1. Create text mask (white on black)
    mask_img = Image.new('L', (tw + 4, th + 4), 0)
    mask_draw = ImageDraw.Draw(mask_img)
    mask_draw.text((-bb[0] + 2, -bb[1] + 2), text, font=font, fill=255)

    # 2. Create gradient matching text bbox size
    grad = gradient_fill(tw + 4, th + 4, top_color, bot_color)

    # 3. Paste gradient onto canvas using mask
    canvas.paste(grad, (int(x + bb[0] - 2), int(y + bb[1] - 2)), mask=mask_img)


def lightning_points(cx, cy, h):
    """
    Classic WAJE lightning bolt — narrow, tall, slanted.
    Width ~38% of height like in the UI logo.
    """
    w = h * 0.38
    return [
        (cx + w * 0.42,  cy - h * 0.50),   # top apex (right)
        (cx - w * 0.20,  cy - h * 0.04),   # mid-left (start of crosspiece)
        (cx + w * 0.58,  cy - h * 0.04),   # mid-right (end of crosspiece)
        (cx - w * 0.42,  cy + h * 0.50),   # bottom apex (left)
        (cx + w * 0.20,  cy + h * 0.04),   # mid-right lower
        (cx - w * 0.58,  cy + h * 0.04),   # mid-left lower
    ]


def draw_bolt_gradient(img, cx, cy, h):
    """Draw lightning bolt with vertical orange gradient fill."""
    w_half = h * 0.38 * 0.58  # half-width: w*0.58 is max x offset in new polygon
    pts = lightning_points(cx, cy, h)

    # Create bolt mask (bounding box around center)
    bolt_bb_w = int(w_half * 2 + 8)
    bolt_bb_h = int(h + 8)
    bolt_img  = Image.new('RGBA', (bolt_bb_w, bolt_bb_h), (0, 0, 0, 0))
    bolt_draw = ImageDraw.Draw(bolt_img)

    # Shift points to local coords
    ox = cx - w_half - 4
    oy = cy - h / 2 - 4
    local_pts = [(p[0] - ox, p[1] - oy) for p in pts]
    bolt_draw.polygon(local_pts, fill=(255, 255, 255, 255))

    # Create gradient matching bolt size
    grad = gradient_fill(bolt_bb_w, bolt_bb_h, ORANGE_T, ORANGE_B).convert('RGBA')

    # Apply mask: gradient visible only where bolt is white
    r, g, b, a = bolt_img.split()
    grad.putalpha(a)

    # Paste onto main canvas
    img.paste(grad, (int(ox), int(oy)), mask=grad.split()[3])

    # Add subtle glow: semi-transparent larger bolt behind
    glow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    gd   = ImageDraw.Draw(glow)
    for radius in [6, 3]:
        gpts = lightning_points(cx, cy, h + radius * 3)
        gd.polygon(gpts, fill=(*ORANGE_B, 40))
    img.alpha_composite(glow)


def compose_icon(size, adaptive_fg=False):
    """
    Compose the full icon.
    adaptive_fg = True → transparent background, content in 72/108 safe zone.
    """
    canvas_size = size

    if adaptive_fg:
        img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        content = int(canvas_size * 0.667)
    else:
        bg = draw_bg(canvas_size)
        img = bg.convert('RGBA')
        content = canvas_size

    draw_wa_bolt(img, canvas_size // 2, canvas_size // 2, content)

    if adaptive_fg:
        return img
    # Return as RGB (Play Store / standard icons must not have alpha)
    out = Image.new('RGB', (canvas_size, canvas_size), BG_DARK)
    out.paste(img, mask=img.split()[3])
    return out


def draw_wa_bolt(img, cx, cy, content):
    """
    Draw WA⚡ — W and A touching, bolt immediately attached to A.
    Like the WAJE logo but only the left portion.
    """
    s = content

    # ── Font — auto-size so WA⚡ fills ~88% width, all attached ─────────────
    margin_ratio = 0.10
    usable_w = s * (1 - 2 * margin_ratio)

    # Render "WA" as a single string so the font handles its own kerning
    for letter_pt in range(int(s * 0.60), int(s * 0.15), -2):
        font = ImageFont.truetype(FONT_PATH, letter_pt, index=FONT_INDEX)
        bb_wa = font.getbbox("WA")
        wa_w  = bb_wa[2] - bb_wa[0]
        wa_h  = bb_wa[3] - bb_wa[1]
        bolt_h   = wa_h * 1.65          # bolt 65% taller — sticks out above AND below
        bolt_vis = bolt_h * 0.38 * 1.16  # total visible width (w*0.58+w*0.58)
        total_w  = wa_w + bolt_vis
        if total_w <= usable_w:
            break

    start_x      = cx - total_w / 2
    letter_top_y = cy - wa_h / 2

    # ── Draw "WA" as one unit with blue gradient ───────────────────────────
    render_text_with_gradient(
        img, font, "WA",
        start_x - bb_wa[0],
        letter_top_y - bb_wa[1],
        BLUE_TOP, BLUE_BOT,
    )

    # ── Draw ⚡ bolt — left edge immediately after WA ─────────────────────
    wa_right = start_x + wa_w
    bolt_cx  = wa_right + bolt_h * 0.38 * 0.58  # left edge of bolt = right of WA
    bolt_cy  = cy
    draw_bolt_gradient(img, bolt_cx, bolt_cy, bolt_h)


# ── Generate all sizes ────────────────────────────────────────────────────
BASE = "/Users/lucaschiano/Progetti/apps/wolf_lab/android/app/src/main/res"
PLAY = "/Users/lucaschiano/Progetti/apps/wolf_lab/assets/icons"

print("Generating WAJE W⚡A icons (logo style)...")

sizes_map = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}
for folder, px in sizes_map.items():
    for name in ("ic_launcher.png", "ic_launcher_round.png"):
        compose_icon(px).save(f"{BASE}/{folder}/{name}", "PNG")
    print(f"  ✓ {folder}/")

# Adaptive foreground
adaptive_sz = 432
fg = compose_icon(adaptive_sz, adaptive_fg=True)
os.makedirs(f"{BASE}/drawable", exist_ok=True)
fg.save(f"{BASE}/drawable/ic_launcher_foreground.png", "PNG")
print(f"  ✓ drawable/ic_launcher_foreground.png")

# Adaptive background (solid)
bg = draw_bg(adaptive_sz)
bg.save(f"{BASE}/drawable/ic_launcher_background.png", "PNG")
print(f"  ✓ drawable/ic_launcher_background.png")

# Play Store 512×512
os.makedirs(PLAY, exist_ok=True)
compose_icon(512).save(f"{PLAY}/ic_launcher_512.png", "PNG")
print(f"  ✓ assets/icons/ic_launcher_512.png  ← Play Store")

print("\nDone!")
