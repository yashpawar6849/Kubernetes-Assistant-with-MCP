"""Compose the final 1080p MP4: title card, framed terminal, per-section captions, outro.
usage: uv run --with pillow --with imageio-ffmpeg python scripts/make-video.py demo.cast raw.gif out.mp4
Caption timing: the cast is replayed with agg's idle-time cap (2s) to map section starts onto GIF time."""
import json, re, sys
import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFont, ImageFilter

cast, gif_path, out = sys.argv[1:4]
IDLE_CAP, FPS, W, H = 2.0, 30, 1920, 1080
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans{}.ttf"
font = lambda size, bold=False: ImageFont.truetype(FONT.format("-Bold" if bold else ""), size)

CAPTIONS = {
    1: ("1 · The broken app", "checkout is stuck in CrashLoopBackOff"),
    2: ("2 · Ask the assistant", "Three read-only tool calls reveal the root cause"),
    3: ("3 · Restart with human approval", "restart_deployment is marked destructive, so the host asks first"),
    4: ("4 · Recovered", "checkout is healthy again"),
    5: ("5 · Guardrail", "The server's allow-list rejects namespace prod before touching the cluster"),
    6: ("6 · RBAC is the real boundary", "Even a buggy server could not read secrets, exec or delete"),
    7: ("7 · Audit trail", "Every call, including the rejected one, is logged"),
}

# --- section start times on agg's (idle-capped) timeline
events = [json.loads(l) for l in open(cast).read().splitlines()[1:]]
adj, t, prev = [], 0.0, 0.0
for e in events:
    t += min(e[0] - prev, IDLE_CAP); prev = e[0]; adj.append(t)
starts = {}
for e, a in zip(events, adj):
    m = re.search(r"(\d)\. (The broken|Ask the|Restart, with|Recovered|Guardrail|RBAC is|Audit trail)", e[2])
    if m: starts.setdefault(int(m.group(1)), a)
bounds = sorted(starts.items(), key=lambda kv: kv[1])

def section_at(t):
    cur = None
    for n, s in bounds:
        if t >= s: cur = n
    return cur

# --- drawing helpers
def gradient():
    bg = Image.new("RGB", (W, H)); d = ImageDraw.Draw(bg)
    for y in range(H):
        k = y / H; d.line([(0, y), (W, y)], fill=(int(22 + 26 * k), int(26 + 18 * k), int(52 + 44 * k)))
    return bg
BG = gradient()

gif = Image.open(gif_path); gw, gh = gif.size
BAR, R = 44, 14
wx, wy = (W - gw) // 2, 58
def window_base():
    b = BG.copy()
    sh = Image.new("L", (W, H), 0)
    ImageDraw.Draw(sh).rounded_rectangle([wx, wy + 18, wx + gw, wy + BAR + gh + 18], R, fill=170)
    b.paste((0, 0, 0), (0, 0), sh.filter(ImageFilter.GaussianBlur(26)))
    d = ImageDraw.Draw(b)
    d.rounded_rectangle([wx, wy, wx + gw, wy + BAR + gh], R, fill=(0, 0, 0))
    d.rounded_rectangle([wx, wy, wx + gw, wy + BAR], R, fill=(46, 46, 48))
    d.rectangle([wx, wy + BAR - R, wx + gw, wy + BAR], fill=(46, 46, 48))
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        cx, cy = wx + 28 + i * 28, wy + BAR // 2
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=c)
    d.text((wx + gw / 2, wy + BAR / 2), "k8s-mcp-demo — zsh", fill=(185, 185, 185), font=font(17), anchor="mm")
    return b
BASE = window_base()
mask = Image.new("L", (gw, gh), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, -R, gw, gh], R, fill=255)

def caption(img, n):
    title, sub = CAPTIONS[n]
    cy = wy + BAR + gh + 36
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(ov)
    d.rounded_rectangle([wx, cy, wx + gw, cy + 84], 16, fill=(255, 255, 255, 28), outline=(255, 255, 255, 50))
    d.rectangle([wx + 18, cy + 18, wx + 24, cy + 66], fill=(77, 163, 255, 255))
    d.text((wx + 44, cy + 14), title, font=font(28, True), fill=(255, 255, 255, 255))
    d.text((wx + 44, cy + 50), sub, font=font(20), fill=(190, 200, 220, 255))
    return Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")

cache = {}
def terminal_frame(i, n):
    if (i, n) not in cache:
        gif.seek(i)
        f = BASE.copy(); f.paste(gif.convert("RGB"), (wx, wy + BAR), mask)
        cache[(i, n)] = caption(f, n) if n else f
    return cache[(i, n)]

def card(lines, sizes):
    img = BG.copy(); d = ImageDraw.Draw(img)
    y = H // 2 - 120
    for text, size, bold, col in lines:
        d.text((W // 2, y), text, font=font(size, bold), fill=col, anchor="mm"); y += size + 26
    d.rounded_rectangle([W // 2 - 60, H // 2 + 130, W // 2 + 60, H // 2 + 134], 2, fill=(77, 163, 255))
    return img
WHITE, GREY = (255, 255, 255), (170, 182, 205)
INTRO = card([("Build Your Own AI", 76, True, WHITE), ("Kubernetes Assistant with MCP", 76, True, WHITE),
              ("Live demo  ·  FastMCP  ·  kind  ·  RBAC", 30, False, GREY)], None)
OUTRO = card([("Read-only tools. One guarded write.", 56, True, WHITE),
              ("RBAC is the real boundary.", 56, True, (120, 190, 255)),
              ("Every call audited.", 30, False, GREY)], None)

# --- GIF frame timeline
starts_g, acc = [], 0.0
for i in range(gif.n_frames):
    gif.seek(i); starts_g.append(acc); acc += gif.info.get("duration", 100) / 1000
total = acc

writer = imageio_ffmpeg.write_frames(out, (W, H), fps=FPS, codec="libx264", quality=7,
                                     pix_fmt_out="yuv420p", macro_block_size=1,
                                     output_params=["-preset", "slow", "-movflags", "+faststart"])
writer.send(None)
def put(img): writer.send(img.tobytes())
def hold(img, sec):
    for _ in range(int(sec * FPS)): put(img)
def fade(a, b, sec=0.6):
    n = int(sec * FPS)
    for k in range(n): put(Image.blend(a, b, (k + 1) / n))

first = terminal_frame(0, None)
hold(INTRO, 3.0); fade(INTRO, first)
idx = 0
for fr in range(int(total * FPS)):
    t = fr / FPS
    while idx + 1 < len(starts_g) and starts_g[idx + 1] <= t: idx += 1
    put(terminal_frame(idx, section_at(t)))
last = terminal_frame(len(starts_g) - 1, section_at(total))
hold(last, 1.0); fade(last, OUTRO); hold(OUTRO, 3.5)
writer.close()
print(f"{out}: {total + 8.7:.0f}s, {W}x{H}, sections at", {n: round(s, 1) for n, s in bounds})
