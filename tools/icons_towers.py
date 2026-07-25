"""Modellen voor de tower-iconen (CTRL-ALT-DEFEND).

Elke functie bouwt één icoon uit primitieven van blender_icon_rig. De rig levert camera,
licht en palet; hier staat alleen de vorm. Draaien:

    exec(open("/Users/nijntje/Documents/projecten/game/tools/icons_towers.py").read())
    build_all()          # of: build_one("coffee_1")

Renders komen in art/blender_out/ op 512px; daarna tools/smooth_downscale.py 128 <png>.

Kleurtaal (uit art/STYLE_GUIDE.md): mail = indigo, CEO = rood, spam filter = groen,
scrum = indigo/amber post-its, koffie = amber. "dark" is de standaard behuizing.
"""
import importlib.util, math, sys

RIG_PATH = "/Users/nijntje/Documents/projecten/game/tools/blender_icon_rig.py"
R = math.radians


def _load_rig():
    spec = importlib.util.spec_from_file_location("icon_rig", RIG_PATH)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["icon_rig"] = mod
    spec.loader.exec_module(mod)
    return mod


# ---------------------------------------------------------------- towers lvl 1

def coffee_1(g, m):
    """Coffee Machine — koffieautomaat met display, uitloop en een kopje op de bak."""
    g.box((1.00, 0.80, 1.50), (0, 0, 0.75), m["dark"])
    g.box((0.62, 0.06, 0.34), (0, -0.41, 1.08), m["indigo"])       # display
    g.box((0.34, 0.06, 0.09), (0, -0.41, 0.80), m["light"])        # knoppenrij
    g.box((0.56, 0.30, 0.05), (0, -0.52, 0.03), m["metal"])        # druppelbak
    g.cyl(0.06, 0.22, (0, -0.44, 0.55), m["metal"])                # uitloop
    g.cyl(0.14, 0.20, (0, -0.52, 0.15), m["light"])                # kopje
    g.cyl(0.115, 0.03, (0, -0.52, 0.24), m["amber"])               # koffie


def auto_1(g, m):
    """Auto-Reply — envelop op een sokkel, naar de kijker geleund zodat de flap-V leest."""
    g.box((0.94, 0.56, 0.14), (0, 0.05, 0.07), m["metal"])         # sokkel
    env = [g.box((1.16, 0.16, 0.82), (0, 0, 0.52), m["light"])]    # envelop
    # Flap als één driehoekige plaat. Twee losse armen kruisen elkaar bij het minste
    # verloop en lezen dan als een X in plaats van een envelop.
    # Driehoekig prisma (r1 == r2; met r2=0 krijg je een piramide). Het eerste hoekpunt
    # ligt op +Y, dus Rx(-90) zet de punt naar beneden en de dikte langs Y.
    flap = g.cone(0.60, 0.60, 0.07, (0, -0.10, 0.68), m["indigo"], rot=(R(-90), 0, 0), verts=3)
    flap.scale = (1.0, 0.62, 1.0)          # platter dan gelijkzijdig
    env.append(flap)
    env.append(g.box((1.16, 0.05, 0.10), (0, -0.09, 0.20), m["amber"]))
    g.tilt(env, -32, pivot=(0, 0, 0.12))


def ceo_1(g, m):
    """The CEO Email — rode megafoon op een paal: dit gaat naar iedereen tegelijk."""
    g.cyl(0.38, 0.10, (0, 0, 0.05), m["metal"])                    # voet
    g.cyl(0.08, 0.74, (0, 0.10, 0.45), m["dark"])                  # paal
    horn = [g.cone(0.15, 0.50, 0.66, (0, -0.14, 0.92), m["red"]),  # trechter
            g.cyl(0.50, 0.05, (0, -0.14, 1.23), m["amber"]),       # rand
            g.cyl(0.11, 0.18, (0, -0.14, 0.55), m["dark"])]        # achterkant
    g.tilt(horn, -50, pivot=(0, -0.14, 0.80))


def phones_1(g, m):
    """Headphones lvl 1 — earbuds: open doosje met twee duidelijk zichtbare dopjes."""
    g.box((0.94, 0.80, 0.30), (0, 0.02, 0.15), m["light"])         # case
    g.box((0.74, 0.60, 0.05), (0, -0.02, 0.30), m["dark"])         # binnenbak
    lid = [g.box((0.94, 0.08, 0.50), (0, 0.42, 0.55), m["light"])]
    g.tilt(lid, 28, pivot=(0, 0.42, 0.30))                         # deksel open
    for x in (-0.22, 0.22):
        g.cyl(0.17, 0.16, (x, -0.06, 0.40), m["dark"])             # dopje
        g.cyl(0.06, 0.26, (x, -0.06, 0.22), m["metal"])            # steeltje
        g.cyl(0.055, 0.03, (x, -0.06, 0.48), m["metal"])           # gaasje
    g.cyl(0.04, 0.03, (0, -0.40, 0.24), m["glow"], rot=(R(90), 0, 0))   # statuslampje


def filter_1(g, m):
    """Spam Filter — groene trechter met raster: alles gaat er eerst doorheen."""
    g.cyl(0.40, 0.10, (0, 0, 0.05), m["metal"])                    # voet
    g.cyl(0.11, 0.34, (0, 0, 0.24), m["metal"])                    # afvoerbuis
    g.cone(0.16, 0.62, 0.56, (0, 0, 0.66), m["green"])             # trechter (wijd boven)
    g.cyl(0.56, 0.05, (0, 0, 0.86), m["dark"])                     # holte
    g.arc(0.62, 0.05, (0, 0, 0.94), m["light"])                    # rand
    for rz in (R(30), R(-30)):
        g.box((1.24, 0.05, 0.04), (0, 0, 0.93), m["light"], rotz=rz)   # raster


def scrum_1(g, m):
    """Scrum Master — post-it-bord op poten; hier wordt het werk zichtbaar."""
    for x in (-0.46, 0.46):
        g.box((0.08, 0.08, 0.54), (x, 0.14, 0.27), m["metal"])     # poot
    board = [g.box((1.16, 0.12, 0.80), (0, 0, 0.94), m["light"])]
    notes = [(-0.34, 1.16, "amber"), (0.01, 1.18, "green"), (0.35, 1.14, "indigo"),
             (-0.30, 0.80, "indigo"), (0.16, 0.78, "amber")]
    for x, z, col in notes:
        board.append(g.box((0.24, 0.03, 0.24), (x, -0.07, z), m[col], bevel=0.012))
    g.tilt(board, -26, pivot=(0, 0, 0.54))


BUILDERS = {
    "coffee_1": coffee_1, "auto_1": auto_1, "ceo_1": ceo_1,
    "phones_1": phones_1, "filter_1": filter_1, "scrum_1": scrum_1,
}


def build_one(name):
    g = _load_rig()
    mats = g.setup()
    BUILDERS[name](g, mats)
    g.render(name)
    return f"{name} -> {g.OUT}"


def build_all():
    g = _load_rig()
    mats = g.setup()
    done = []
    for name, fn in BUILDERS.items():
        g.clear()
        fn(g, mats)
        g.render(name)
        done.append(name)
    return done
