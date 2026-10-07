"""Tiny CLI to call one MCP tool over stdio:  call-tool.py <tool> '{"json": "args"}'"""
import asyncio, json, sys
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def main(tool, args):
    server = Path(__file__).resolve().parent.parent / "server" / "server.py"
    async with stdio_client(StdioServerParameters(command=sys.executable, args=[str(server)])) as (r, w), \
               ClientSession(r, w) as s:
        await s.initialize()
        res = await s.call_tool(tool, args)
        print(("ERROR: " if res.isError else "") + res.content[0].text)

asyncio.run(main(sys.argv[1], json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}))
