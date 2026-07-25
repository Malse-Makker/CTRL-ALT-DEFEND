# Game — omgeving

Top-down tower defense game in **Godot**, met **Blender** voor 3D-assets. Aangestuurd via Claude Code + MCP.

## Geïnstalleerd
- **Godot** 4.7.1 → `/Applications/Godot.app` (binary: `/Applications/Godot.app/Contents/MacOS/Godot`)
- **Blender** 5.2.0 LTS → `/Applications/Blender.app`
- **Node.js** 26.x + **uv** 0.11.x (via Homebrew)

## MCP-servers (geconfigureerd in `.mcp.json`)
- **godot** — [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)
  - Locatie: `~/.claude/mcp-servers/godot-mcp/` (gebouwd, `build/index.js`)
  - Tools o.a.: create_scene, add_node, load_sprite, run_project, launch_editor, get_debug_output
- **blender** — [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
  - Server draait via `uvx blender-mcp`
  - Tools o.a.: get_scene_info, execute_blender_code, get_viewport_screenshot, PolyHaven/Sketchfab/Hyper3D asset-import

## Nog te doen (eenmalig, handmatig in de GUI)
1. **Claude Code opnieuw openen in deze map** zodat `.mcp.json` wordt geladen; keur bij de prompt beide servers goed.
2. **Blender-addon aanzetten** (nodig voordat de blender-MCP werkt):
   - Blender openen → Edit → Preferences → Add-ons → zoek "Blender MCP" → aanvinken
     (de addon staat al in de addon-map als `blender_mcp_addon.py`)
   - In de 3D-viewport: druk `N` voor de sidebar → tab **BlenderMCP** → **Connect to Claude**
3. Voor Godot: maak/open een Godot-project in deze map; de godot-MCP werkt headless zonder extra stappen.
