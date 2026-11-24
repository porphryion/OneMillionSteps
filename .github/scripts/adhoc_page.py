"""Makes the Ad Hoc install page: the IPA, its manifest and an index page.

Safari on a registered iPhone installs the app from the index page through
an itms-services link, which points at the manifest, which points at the
IPA. All three go into OUT_DIR/TOKEN/, and the site is published from
OUT_DIR, so the page lives at BASE_URL/TOKEN/.

Usage: adhoc_page.py IPA OUT_DIR BASE_URL TOKEN VERSION BUILD
"""

import html
import plistlib
import shutil
import sys
import urllib.parse
from pathlib import Path

BUNDLE_ID = "com.onemillionsteps.oneMillionSteps"
TITLE = "1 Million Steps"

# Colors and type follow design-system/MASTER.md (cream and plum light theme,
# "night walk" dark theme, orange pressable button on a darker lip).
PAGE = """<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>{title} test sürümü</title>
<style>
  :root {{
    --surface: #FFF5E8;
    --card: #FFFFFF;
    --ink: #2E2142;
    --muted: #5B4B73;
    --primary: #FF8A1F;
    --on-primary: #2E2142;
    --lip: #CC5A0C;
    --border: #F1DCC4;
  }}
  @media (prefers-color-scheme: dark) {{
    :root {{
      --surface: #1C1730;
      --card: #2A2342;
      --ink: #FFF6EC;
      --muted: #CFC3E6;
      --border: #3A3158;
    }}
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0;
    min-height: 100vh;
    display: grid;
    place-items: center;
    padding: 24px 16px;
    background: var(--surface);
    color: var(--ink);
    font: 600 16px/1.5 ui-rounded, -apple-system, "SF Pro Rounded", system-ui, sans-serif;
  }}
  main {{
    width: 100%;
    max-width: 420px;
    background: var(--card);
    border: 2px solid var(--border);
    border-radius: 28px;
    box-shadow: 0 6px 0 var(--border);
    padding: 28px 24px;
    text-align: center;
  }}
  h1 {{ margin: 0 0 4px; font-size: 28px; line-height: 1.2; font-weight: 800; }}
  .version {{ margin: 0 0 24px; color: var(--muted); font-variant-numeric: tabular-nums; }}
  .install {{
    display: block;
    padding: 16px 24px;
    border-radius: 20px;
    background: var(--primary);
    color: var(--on-primary);
    font-size: 20px;
    font-weight: 800;
    text-decoration: none;
    box-shadow: 0 6px 0 var(--lip);
    transition: transform 80ms ease-out, box-shadow 80ms ease-out;
  }}
  .install:active {{ transform: translateY(6px); box-shadow: 0 0 0 var(--lip); }}
  .install:focus-visible {{ outline: 3px solid var(--ink); outline-offset: 4px; }}
  ol {{ margin: 28px 0 0; padding-left: 20px; text-align: left; color: var(--muted); }}
  li + li {{ margin-top: 8px; }}
</style>
</head>
<body>
<main>
  <h1>{title}</h1>
  <p class="version">Test sürümü · {version} ({build})</p>
  <a class="install" href="{install_url}">Yükle</a>
  <ol>
    <li>Bu sayfayı iPhone'da Safari ile aç.</li>
    <li>Yükle'ye dokun, sonra çıkan pencerede Yükle'yi onayla.</li>
    <li>Uygulama ana ekranına iner. Sadece kayıtlı iPhone'larda çalışır.</li>
  </ol>
</main>
</body>
</html>
"""


def main():
    ipa, out_dir, base_url, token, version, build = sys.argv[1:7]
    page_dir = Path(out_dir) / token
    page_dir.mkdir(parents=True, exist_ok=True)

    # The build number is in the IPA name so Safari never installs a cached
    # older build.
    ipa_name = f"one_million_steps-{build}.ipa"
    shutil.copy(ipa, page_dir / ipa_name)

    page_url = f"{base_url.rstrip('/')}/{token}"
    manifest = {
        "items": [
            {
                "assets": [{"kind": "software-package", "url": f"{page_url}/{ipa_name}"}],
                "metadata": {
                    "bundle-identifier": BUNDLE_ID,
                    "bundle-version": version,
                    "kind": "software",
                    "title": TITLE,
                },
            }
        ]
    }
    with open(page_dir / "manifest.plist", "wb") as file:
        plistlib.dump(manifest, file)

    manifest_url = urllib.parse.quote(f"{page_url}/manifest.plist", safe="")
    install_url = f"itms-services://?action=download-manifest&url={manifest_url}"
    (page_dir / "index.html").write_text(
        PAGE.format(
            title=html.escape(TITLE),
            version=html.escape(version),
            build=html.escape(build),
            install_url=html.escape(install_url),
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
