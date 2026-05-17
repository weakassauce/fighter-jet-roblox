"""Extract vertex + triangle data from a GLB and emit a Luau data module.

The output is consumed at runtime by JetMeshBuilder.luau via EditableMesh, so
the asset lives entirely inside the Rojo project — no Roblox upload needed.

Usage:
    blender --background --python extract_mesh_data.py -- <in.glb> <out.luau> [max_verts]
"""

import bpy
import bmesh
import sys


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
        print("no mesh objects found in GLB", file=sys.stderr)
        sys.exit(1)

    # Total vertices across meshes (rough — before triangulation)
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
    all_tris: list[tuple[int, int, int]] = []
    vert_offset = 0
    for obj in meshes:
        mw = obj.matrix_world
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.verts.ensure_lookup_table()
        bm.faces.ensure_lookup_table()

        for v in bm.verts:
            wp = mw @ v.co
            all_verts.append((wp.x, wp.y, wp.z))

        for f in bm.faces:
            if len(f.verts) == 3:
                idx = [v.index for v in f.verts]
                all_tris.append(
                    (idx[0] + vert_offset, idx[1] + vert_offset, idx[2] + vert_offset)
                )

        vert_offset = len(all_verts)
        bm.free()

    print(f"final: {len(all_verts)} verts, {len(all_tris)} tris", flush=True)

    with open(dst, "w", encoding="utf-8", newline="\n") as f:
        f.write(f"-- AUTO-GENERATED from {src.split('/')[-1]} via Blender.\n")
        f.write(f"-- {len(all_verts)} vertices, {len(all_tris)} triangles\n")
        f.write("-- Edit upstream and re-run scripts/extract_mesh_data.py to update.\n")
        f.write("\n")
        f.write("return {\n")
        f.write("\tvertices = {\n")
        for v in all_verts:
            f.write(f"\t\t{{{v[0]:.4f},{v[1]:.4f},{v[2]:.4f}}},\n")
        f.write("\t},\n")
        f.write("\ttriangles = {\n")
        for t in all_tris:
            f.write(f"\t\t{{{t[0] + 1},{t[1] + 1},{t[2] + 1}}},\n")  # 1-indexed
        f.write("\t},\n")
        f.write("}\n")


if __name__ == "__main__":
    main()
