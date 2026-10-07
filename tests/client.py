"""Smoke test: talks to the server over stdio exactly like a host would."""
import asyncio
import subprocess
import sys
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

ROOT = Path(__file__).resolve().parent.parent
KUBECTL = ["kubectl", "--context", "kind-mcp-demo", "-n", "shop"]


async def main():
    params = StdioServerParameters(command=sys.executable, args=[str(ROOT / "server" / "server.py")])
    async with stdio_client(params) as (r, w), ClientSession(r, w) as s:
        await s.initialize()

        async def call(tool, **args):
            res = await s.call_tool(tool, args)
            text = res.content[0].text if res.content else ""
            print(f"\n$ {tool}({args})  {'[ERROR]' if res.isError else '[ok]'}\n{text}")
            return res, text

        for t in (await s.list_tools()).tools:
            a = t.annotations
            print(f"tool {t.name:19} readOnly={a.readOnlyHint} destructive={a.destructiveHint}")
        print("prompts:", [p.name for p in (await s.list_prompts()).prompts])

        _, pods = await call("list_pods", namespace="shop")
        checkout = next(l.split()[0] for l in pods.splitlines() if l.startswith("checkout"))
        await call("get_events", namespace="shop")
        await call("get_pod_logs", pod=checkout, namespace="shop", tail=5)

        print("\n--- guardrails ---")
        res, _ = await call("restart_deployment", name="checkout", namespace="prod")
        assert res.isError, "prod must be rejected"
        res, text = await call("list_pods", namespace="kube-system")
        assert "403" in text, "RBAC must refuse kube-system"

        # 500-line pod to prove the 200-line cap
        subprocess.run(KUBECTL + ["run", "logspam", "--image=busybox:1.36", "--restart=Never", "--",
                                  "sh", "-c", "seq 1 500; sleep 60"], check=True, capture_output=True)
        subprocess.run(KUBECTL + ["wait", "--for=condition=Ready", "pod/logspam", "--timeout=60s"],
                       check=True, capture_output=True)
        try:
            _, big = await call("get_pod_logs", pod="logspam", namespace="shop", tail=100000)
            n = len(big.splitlines())
            print(f"\nrequested tail=100000, got {n} lines")
            assert n == 200, "log cap violated"
        finally:
            subprocess.run(KUBECTL + ["delete", "pod", "logspam", "--now"], capture_output=True)

        res, _ = await call("restart_deployment", name="checkout", namespace="shop")
        assert not res.isError
        print("\nALL CHECKS PASSED")


asyncio.run(main())
