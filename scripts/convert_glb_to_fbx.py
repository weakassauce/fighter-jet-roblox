"""Convert a GLB file to FBX using Blender's headless Python API.

Usage:
    blender --background --python convert_glb_to_fbx.py -- <input.glb> <output.fbx>
"""
import bpy
import sys


def main():
    argv = sys.argv
    # Args after '--' are passed to the script
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []

    if len(argv) < 2:
        print("usage: convert_glb_to_fbx.py -- <input.glb> <output.fbx>", file=sys.stderr)
        sys.exit(2)

    src, dst = argv[0], argv[1]

    # Clear the default scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # Import GLB
    bpy.ops.import_scene.gltf(filepath=src)

    # Export FBX — embed textures, copy media, Y-up axis (matches Roblox's
    # default), apply unit scale.
    bpy.ops.export_scene.fbx(
        filepath=dst,
        use_selection=False,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        path_mode="COPY",
        embed_textures=True,
        axis_forward="-Z",
        axis_up="Y",
        bake_space_transform=True,
        object_types={"MESH", "EMPTY"},
        mesh_smooth_type="FACE",
    )

    print(f"Wrote {dst}", flush=True)


if __name__ == "__main__":
    main()
