"""Gets the app's bundle ID and profiles ready before fetch-signing-files.

- Turns on the bundle ID capabilities the app's entitlements need (HealthKit,
  see ios/Runner/Runner.entitlements). Turning one on invalidates the old
  profiles, so they are deleted and fetch-signing-files makes new ones.
- With --adhoc, deletes the active Ad Hoc profiles. A profile keeps the
  devices it was made with, so the new one includes every registered iPhone.

Needs APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_IDENTIFIER and
APP_STORE_CONNECT_PRIVATE_KEY in the environment. Uses PyJWT and requests,
which Codemagic CLI tools already install.
"""

import argparse
import sys

from testflight_testers import BUNDLE_ID, Api

# Capability types the entitlements in ios/Runner/Runner.entitlements need.
CAPABILITIES = ["HEALTHKIT"]


def find_bundle_id(api):
    matches = [
        b
        for b in api.get("/bundleIds", **{"filter[identifier]": BUNDLE_ID}, limit=200)["data"]
        if b["attributes"].get("identifier") == BUNDLE_ID
    ]
    if not matches:
        sys.exit(f"No bundle ID {BUNDLE_ID} in the developer account.")
    return matches[0]["id"]


def enable_capabilities(api, bundle_id):
    """Returns True when a capability was turned on now."""
    enabled = {
        c["attributes"].get("capabilityType")
        for c in api.get(f"/bundleIds/{bundle_id}/bundleIdCapabilities", limit=200)["data"]
    }
    changed = False
    for capability in CAPABILITIES:
        if capability in enabled:
            print(f"{capability} is on.")
            continue
        print(f"Turning on {capability}.")
        api.post(
            "/bundleIdCapabilities",
            {
                "type": "bundleIdCapabilities",
                "attributes": {"capabilityType": capability},
                "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}},
            },
        )
        changed = True
    return changed


def delete_profiles(api, bundle_id, types):
    profiles = api.get(f"/bundleIds/{bundle_id}/profiles", limit=200)["data"]
    doomed = [p for p in profiles if p["attributes"].get("profileType") in types]
    for profile in doomed:
        a = profile["attributes"]
        print(f"Deleting {a.get('profileType')} profile {a.get('name')} ({profile['id']}).")
        api.call("DELETE", f"/profiles/{profile['id']}")
    print(f"Deleted {len(doomed)} profile(s).")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--adhoc", action="store_true", help="delete the Ad Hoc profiles")
    args = parser.parse_args()

    api = Api()
    bundle_id = find_bundle_id(api)
    if enable_capabilities(api, bundle_id):
        delete_profiles(api, bundle_id, {"IOS_APP_STORE", "IOS_APP_ADHOC", "IOS_APP_DEVELOPMENT"})
    elif args.adhoc:
        delete_profiles(api, bundle_id, {"IOS_APP_ADHOC"})


if __name__ == "__main__":
    main()
