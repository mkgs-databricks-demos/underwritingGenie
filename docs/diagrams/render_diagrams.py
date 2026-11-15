#!/usr/bin/env python3
"""render_diagrams.py - render docs/diagrams/mermaid/*.md to svg/ and html/ with a Databricks theme.
Requires: pip install playwright && playwright install chromium; a local mermaid.min.js (MERMAID_JS env var,
default /tmp/mm/mermaid.min.js). No diagram source leaves the machine."""
import os, re, sys, html
from pathlib import Path
from playwright.sync_api import sync_playwright
D = Path(__file__).parent
MJS = Path(os.environ.get("MERMAID_JS", "/tmp/mm/mermaid.min.js")).read_text()
CFG = {"theme": "base", "themeVariables": {"primaryColor": "#FFFFFF", "primaryBorderColor": "#1B3139",
       "primaryTextColor": "#1B3139", "lineColor": "#1B3139", "secondaryColor": "#EEEDE9", "tertiaryColor": "#F9F7F4",
       "fontFamily": "DM Sans, Helvetica, Arial, sans-serif", "fontSize": "15px", "actorBkg": "#FFFFFF",
       "actorBorder": "#FF3621", "noteBkgColor": "#FFF4F2", "noteBorderColor": "#FF3621"},
       "flowchart": {"htmlLabels": True, "curve": "basis"}, "gantt": {"barHeight": 24}}
PAGE = """<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>{t}</title>
<style>body{{font-family:'DM Sans',Helvetica,Arial,sans-serif;background:#F9F7F4;color:#1B3139;margin:0;padding:32px}}
header{{border-bottom:4px solid #FF3621;padding-bottom:12px;margin-bottom:24px;max-width:1200px}}
h1{{font-size:24px;margin:0}} .sub{{color:#5A6F77;font-size:13px;margin-top:4px}}
.card{{background:#fff;border-radius:12px;box-shadow:0 2px 10px rgba(27,49,57,.08);padding:24px;max-width:1200px;overflow:auto}}
footer{{margin-top:16px;font-size:12px;color:#5A6F77}}</style></head><body>
<header><h1>{t}</h1><div class="sub">Underwriting Cockpit &mdash; Large Group Experience Rating with Genie One &middot; Synthetic, carrier-neutral</div></header>
<div class="card">{svg}</div><footer>Matthew Giglia | Field Engineering &middot; Source: diagrams/mermaid/{f}</footer></body></html>"""
def main():
    import json
    (D/"svg").mkdir(exist_ok=True); (D/"html").mkdir(exist_ok=True)
    with sync_playwright() as p:
        b = p.chromium.launch(); pg = b.new_page()
        pg.set_content("<html><body></body></html>"); pg.add_script_tag(content=MJS)
        pg.evaluate("cfg => mermaid.initialize(Object.assign({startOnLoad:false}, cfg))", CFG)
        for f in sorted((D/"mermaid").glob("*.md")):
            txt = f.read_text(); m = re.search(r"```mermaid\n(.*?)```", txt, re.S)
            title = txt.splitlines()[0].lstrip("# ").strip()
            try:
                svg = pg.evaluate("async ([id,src]) => (await mermaid.render(id, src)).svg", ["d"+f.stem[:2], m.group(1)])
            except Exception as e:
                print("FAIL", f.name, e); continue
            (D/"svg"/(f.stem+".svg")).write_text(svg)
            (D/"html"/(f.stem+".html")).write_text(PAGE.format(t=html.escape(title), svg=svg, f=f.name))
            print("ok", f.name, len(svg))
        b.close()
if __name__ == "__main__": main()
