"""Extract vertex + triangle + per-vertex colour data from a GLB.

For each vertex we sample the material's base-colour texture at the vertex's
UV coordinate so the resulting EditableMesh shows a painted jet, not a
uniform grey blob. No texture upload to Roblox required — colour bakes in.

Usage:
    blender --background --python extract_mesh_data.py -- <in.glb> <out.luau> [max_verts]
"""

import bpy
import bmesh
import sys


def get_texture_sampler(obj):
    """Build a (u, v) -> (r, g, b) sampler for the object's base-color texture."""
    for slot in obj.material_slots:
        mat = slot.material
        if not mat or not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            base = node.inputs.get("Base Color")
            if not base:
                continue
            # Texture path
            if base.is_linked:
                src = base.links[0].from_node
                if src.type == "TEX_IMAGE" and src.image:
                    img = src.image
                    w, h = img.size
                    if w == 0 or h == 0:
                        continue
                    pixels = list(img.pixels)  # flat RGBA floats

                    def sampler(u, v):
                        # GLTF V is Y-up from the bottom, Blender too; image
                        # rows are top-to-bottom so flip Y.
                        uu = u - int(u) if u >= 0 else (1 + (u - int(u)))
                        vv = v - int(v) if v >= 0 else (1 + (v - int(v)))
                        px = max(0, min(w - 1, int(uu * w)))
                        py = max(0, min(h - 1, int((1.0 - vv) * h)))
                        idx = (py * w + px) * 4
                        return pixels[idx], pixels[idx + 1], pixels[idx + 2]

                    return sampler
            # No texture — use constant base colour
            c = base.default_value
            return lambda _u, _v, c=c: (c[0], c[1], c[2])
    return lambda _u, _v: (0.7, 0.72, 0.78)


def main():
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    if len(argv) < 2:
        print("usage: extract_mesh_data.py -- <in.glb> <out.luau> [max_verts]", file=sys.stderr)
        sys.exit(2)

    src = argv[0]
    dst = argv[1]
    max_verts = int(argv[2]) if len(argv) > 2 else 6000

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        print("no mesh objects found", file=sys.stderr)
        sys.exit(1)

    total = sum(len(o.data.vertices) for o in meshes)
    print(f"raw vertices: {total}, target max: {max_verts}", flush=True)
    if total > max_verts:
        ratio = max_verts / total
        print(f"decimating with ratio {ratio:.4f}", flush=True)
        for obj in meshes:
            bpy.context.view_layer.objects.active = obj
            mod = obj.modifiers.new("decimate", "DECIMATE")
            mod.ratio = ratio
            bpy.ops.object.modifier_apply(modifier="decimate")

    all_verts: list[tuple[float, float, float]] = []
    all_colors: list[tuple[float, float, float]] = []
    all_tris: list[tuple[int, int, int]] = []
    vert_offset = 0

    for obj in meshes:
        sampler = get_texture_sampler(obj)
        mw = obj.matrix_world

        # bmesh keeps UV layer access easy
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.verts.ensure_lookup_table()
        bm.faces.ensure_lookup_table()
        uv_layer = bm.loops.layers.uv.active

        # First pass: average UV per vertex from incident loops
        vert_uv: dict[int, tuple[float, float]] = {}
        if uv_layer is not None:
            for face in bm.faces:
                for loop in face.loops:
                    vi = loop.vert.index
                    uv = loop[uv_layer].uv
                    if vi in vert_uv:
                        ou, ov = vert_uv[vi]
                        vert_uv[vi] = ((ou + uv.x) * 0.5, (ov + uv.y) * 0.5)
                    else:
                        vert_uv[vi] = (uv.x, uv.y)

        for v in bm.verts:
            wp = mw @ v.co
            all_verts.append((wp.x, wp.y, wp.z))
            u, vv = vert_uv.get(v.index, (0.5, 0.5))
            r, g, b = sampler(u, vv)
            all_colors.append((r, g, b))

        for f in bm.faces:
            if len(f.verts) == 3:
                idx = [v.index for v in f.verts]
                all_tris.append(
                    (idx[0] + vert_offset, idx[1] + vert_offset, idx[2] + vert_offset)
                )

        vert_offset = len(all_verts)
        bm.free()

    print(
        f"final: {len(all_verts)} verts, {len(all_tris)} tris, {len(all_colors)} colours",
        flush=True,
    )

    with open(dst, "w", encoding="utf-8", newline="\n") as f:
        f.write(f"-- AUTO-GENERATED from {src.split('/')[-1]} via Blender.\n")
        f.write(f"-- {len(all_verts)} verts, {len(all_tris)} tris, with per-vertex colours\n")
        f.write("-- Re-run scripts/extract_mesh_data.py to refresh.\n\n")
        f.write("return {\n")
        f.write("\tvertices = {\n")
        for vt in all_verts:
            f.write(f"\t\t{{{vt[0]:.4f},{vt[1]:.4f},{vt[2]:.4f}}},\n")
        f.write("\t},\n")
        f.write("\tcolors = {\n")
        for c in all_colors:
            f.write(f"\t\t{{{c[0]:.3f},{c[1]:.3f},{c[2]:.3f}}},\n")
        f.write("\t},\n")
        f.write("\ttriangles = {\n")
        for t in all_tris:
            f.write(f"\t\t{{{t[0] + 1},{t[1] + 1},{t[2] + 1}}},\n")
        f.write("\t},\n")
        f.write("}\n")


if __name__ == "__main__":
    main()
