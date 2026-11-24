"""Deletes the app's active Ad Hoc provisioning profiles.

A profile keeps the devices it was made with, so the iOS workflow deletes the
old Ad Hoc profiles before fetch-signing-files makes a new one with every
registered iPhone.

Needs APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_IDENTIFIER and
APP_STORE_CONNECT_PRIVATE_KEY in the environment. Uses PyJWT and requests,
which Codemagic CLI tools already install.
"""

from testflight_testers import BUNDLE_ID, Api


def main():
    api = Api()
    bundle_ids = [
        b
        for b in api.get("/bundleIds", **{"filter[identifier]": BUNDLE_ID}, limit=200)["data"]
        if b["attributes"].get("identifier") == BUNDLE_ID
    ]
    if not bundle_ids:
        print(f"No bundle ID {BUNDLE_ID} yet, so no Ad Hoc profiles to delete.")
        return

    profiles = api.get(f"/bundleIds/{bundle_ids[0]['id']}/profiles", limit=200)["data"]
    adhoc = [
        p
        for p in profiles
        if p["attributes"].get("profileType") == "IOS_APP_ADHOC"
        and p["attributes"].get("profileState") == "ACTIVE"
    ]
    for profile in adhoc:
        print(f"Deleting Ad Hoc profile {profile['attributes'].get('name')} ({profile['id']}).")
        api.call("DELETE", f"/profiles/{profile['id']}")
    print(f"Deleted {len(adhoc)} Ad Hoc profile(s).")


if __name__ == "__main__":
    main()
