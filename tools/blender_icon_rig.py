"""Vaste Blender-rig voor de icon-set (Office Tower Defense).

Draai dit via de Blender MCP (execute_blender_code) of in Blenders scripting-tab.
Het zet camera, belichting, palet en render-instellingen op. Daarna bouw je per icoon
je objecten met box()/cyl() en roep je render("naam") aan.

De hele huisstijl zit in dit bestand: dezelfde hoek, hetzelfde licht en hetzelfde palet
voor elk icoon. Aanpassen = huisstijl aanpassen.
"""
import bpy, math, os, mathutils

OUT = "/Users/nijntje/Documents/projecten/game/art/blender_out"

PAL = {
    "light":  (0.91, 0.92, 0.95),   # off-white behuizing
    "dark":   (0.17, 0.18, 0.26),   # navy body
    "amber":  (0.96, 0.72, 0.25),   # accent warm
    "indigo": (0.42, 0.36, 0.90),   # accent koel
    "metal":  (0.60, 0.63, 0.70),   # voet / details
    "green":  (0.35, 0.80, 0.55),   # status / ok
    "red":    (0.88, 0.30, 0.32),   # gevaar (voor enemies)
}
LIGHTS = {"Key": 120.0, "Fill": 35.0, "Rim": 55.0}

# Camera: ELEV = graden boven de horizon (90 = recht van boven), AZIM = draaiing eromheen.
# Blenders rotation_euler.x is 90 - ELEV; de locatie volgt daaruit, zodat hoek en positie
# nooit uit de pas lopen. Aanpassen = de hele huisstijl kantelt mee.
ELEV = 60.0
AZIM = 45.0
CAM_DIST = 6.0
ORTHO = 3.0
RES = 512


def _cam_transform():
    rx = math.radians(90.0 - ELEV)
    rz = math.radians(AZIM)
    # kijkrichting = lokale -Z na Rx dan Rz; camera staat de andere kant op
    d = (-math.sin(rx) * math.sin(rz), math.sin(rx) * math.cos(rz), -math.cos(rx))
    loc = tuple(-c * CAM_DIST for c in d)
    return loc, (rx, 0.0, rz)


def setup():
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete()
    for c in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
        for b in list(c):
            c.remove(b)

    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 64
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'   # geen filmic -> schone kleuren

    mats = {}
    for name, rgb in PAL.items():
        m = bpy.data.materials.new(name); m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = (*rgb, 1)
        b.inputs["Roughness"].default_value = 0.35
        mats[name] = m
    g = bpy.data.materials.new("glow"); g.use_nodes = True
    gb = g.node_tree.nodes["Principled BSDF"]
    gb.inputs["Base Color"].default_value = (*PAL["green"], 1)
    gb.inputs["Emission Color"].default_value = (*PAL["green"], 1)
    gb.inputs["Emission Strength"].default_value = 4.0
    mats["glow"] = g

    cd = bpy.data.cameras.new("Cam"); cd.type = 'ORTHO'; cd.ortho_scale = ORTHO
    cam = bpy.data.objects.new("Cam", cd); sc.collection.objects.link(cam)
    cam.location, cam.rotation_euler = _cam_transform()
    sc.camera = cam

    rigs = [("Key", (2.6,-2.6,4.2), 5, (math.radians(40),0,math.radians(45))),
            ("Fill", (-3.2,-1.6,1.8), 6, (math.radians(72),0,math.radians(-60))),
            ("Rim", (-1.4,3.2,2.6), 4, (math.radians(115),0,math.radians(200)))]
    for n, loc, size, rot in rigs:
        ld = bpy.data.lights.new(n, 'AREA'); ld.energy = LIGHTS[n]; ld.size = size
        o = bpy.data.objects.new(n, ld); sc.collection.objects.link(o)
        o.location = loc; o.rotation_euler = rot

    w = bpy.data.worlds[0] if bpy.data.worlds else bpy.data.worlds.new("W")
    sc.world = w; w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.28, 0.30, 0.38, 1)   # zacht omgevingslicht
    bg.inputs[1].default_value = 0.55
    return mats


def box(size, loc, m, rotz=0.0, bevel=0.035, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    o.rotation_euler = rot if rot is not None else (0, 0, rotz)
    bm = o.modifiers.new("bev", 'BEVEL'); bm.width = bevel; bm.segments = 3
    o.data.materials.append(m); bpy.ops.object.shade_smooth()
    return o


def _smooth(o):
    # Alleen ronde flanken smoothen; platte deksels moeten scherp blijven.
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(40))
    except AttributeError:
        bpy.ops.object.shade_smooth()
    return o


def cyl(r, h, loc, m, rot=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, vertices=32)
    o = bpy.context.object; o.rotation_euler = rot
    o.data.materials.append(m)
    return _smooth(o)


def cone(r1, r2, h, loc, m, rot=(0.0, 0.0, 0.0), verts=32):
    """verts=3 geeft een driehoekige plaat — handig voor vlaggen, flappen en pijlpunten."""
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=h, location=loc, vertices=verts)
    o = bpy.context.object; o.rotation_euler = rot
    o.data.materials.append(m)
    return _smooth(o)


def arc(major, minor, loc, m, rot=(0.0, 0.0, 0.0)):
    """Torus — als beugel/boog; verstop de helft die je niet wilt zien in een sokkel."""
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     location=loc, rotation=rot,
                                     major_segments=40, minor_segments=14)
    o = bpy.context.object; o.data.materials.append(m)
    return _smooth(o)


def tilt(objs, deg, pivot=(0.0, 0.0, 0.0), axis='X'):
    """Kantel een groep objecten om een pivot. Van bovenaf gezien verdwijnen rechtopstaande
    vlakken (envelop, bord); een paar graden naar de camera leunen maakt ze weer leesbaar."""
    p = mathutils.Vector(pivot)
    m = (mathutils.Matrix.Translation(p)
         @ mathutils.Matrix.Rotation(math.radians(deg), 4, axis)
         @ mathutils.Matrix.Translation(-p))
    for o in objs:
        o.matrix_basis = m @ o.matrix_basis
    return objs


def clear():
    for o in list(bpy.data.objects):
        if o.type == 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)


def render(name):
    bpy.context.scene.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
