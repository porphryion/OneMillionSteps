"""Checks the TestFlight side of the app in App Store Connect and fixes it.

It prints the latest builds, the beta groups and their testers. With --fix it
also makes sure that:

- the latest build has its export compliance answer,
- an internal beta group exists and has the latest build,
- the account holder (or TESTER_EMAIL) is a tester in that group,
- a tester who has not accepted yet gets the invitation again.

The repo is public, so emails are masked in the log.

Needs APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_IDENTIFIER and
APP_STORE_CONNECT_PRIVATE_KEY in the environment.
"""

import argparse
import os
import re
import sys
import time

import jwt
import requests

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.onemillionsteps.oneMillionSteps")
GROUP_NAME = "Internal"
ACCEPTED_STATES = {"ACCEPTED", "INSTALLED"}
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")


def mask_email(email):
    user, _, domain = email.partition("@")
    return f"{user[:1]}***@{domain}"


def scrub(text):
    return EMAIL_RE.sub(lambda m: mask_email(m.group(0)), str(text))


def hide(value):
    """Tells GitHub Actions to mask the value anywhere in the log."""
    if value:
        print(f"::add-mask::{value}")


class ApiError(Exception):
    def __init__(self, response):
        self.status = response.status_code
        try:
            errors = response.json().get("errors", [])
        except ValueError:
            errors = []
        details = "; ".join(e.get("detail") or e.get("title") or "" for e in errors)
        super().__init__(scrub(f"HTTP {self.status}: {details or response.text[:300]}"))


class Api:
    def __init__(self):
        key = os.environ["APP_STORE_CONNECT_PRIVATE_KEY"]
        if "\\n" in key and "\n" not in key:
            key = key.replace("\\n", "\n")
        self.key = key.strip()
        self.key_id = os.environ["APP_STORE_CONNECT_KEY_IDENTIFIER"].strip()
        self.issuer = os.environ["APP_STORE_CONNECT_ISSUER_ID"].strip()
        self.session = requests.Session()

    def token(self):
        now = int(time.time())
        claims = {"iss": self.issuer, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}
        return jwt.encode(claims, self.key, algorithm="ES256", headers={"kid": self.key_id, "typ": "JWT"})

    def call(self, method, path, **kwargs):
        response = self.session.request(
            method,
            API + path,
            headers={"Authorization": f"Bearer {self.token()}"},
            timeout=60,
            **kwargs,
        )
        if response.status_code >= 400:
            raise ApiError(response)
        return response.json() if response.content else {}

    def get(self, path, **params):
        return self.call("GET", path, params=params)

    def post(self, path, data):
        return self.call("POST", path, json={"data": data})

    def patch(self, path, data):
        return self.call("PATCH", path, json={"data": data})


def find_app(api):
    apps = api.get("/apps", **{"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        sys.exit(f"No app with bundle id {BUNDLE_ID} in App Store Connect.")
    return apps[0]


def latest_builds(api, app_id):
    body = api.get(
        "/builds",
        **{
            "filter[app]": app_id,
            "sort": "-uploadedDate",
            "limit": 5,
            "include": "buildBetaDetail,preReleaseVersion",
        },
    )
    included = {(i["type"], i["id"]): i["attributes"] for i in body.get("included", [])}

    def related(build, name):
        data = build.get("relationships", {}).get(name, {}).get("data")
        return included.get((data["type"], data["id"]), {}) if data else {}

    builds = []
    for build in body["data"]:
        detail = related(build, "buildBetaDetail")
        builds.append(
            {
                "id": build["id"],
                "number": build["attributes"].get("version"),
                "version": related(build, "preReleaseVersion").get("version"),
                "uploaded": build["attributes"].get("uploadedDate"),
                "processing": build["attributes"].get("processingState"),
                "expired": build["attributes"].get("expired"),
                "encryption": build["attributes"].get("usesNonExemptEncryption"),
                "internal": detail.get("internalBuildState"),
                "external": detail.get("externalBuildState"),
            }
        )
    return builds


def group_testers(api, group_id):
    return api.get(f"/betaGroups/{group_id}/betaTesters", limit=200)["data"]


def group_build_ids(api, group_id):
    return {b["id"] for b in api.get(f"/betaGroups/{group_id}/builds", limit=50)["data"]}


def find_tester_email(api):
    """Returns (email, first name, last name) of the person to invite."""
    email = os.environ.get("TESTER_EMAIL", "").strip()
    try:
        users = api.get("/users", limit=50)["data"]
    except ApiError as error:
        print(f"Could not list App Store Connect users: {error}")
        users = []

    print(f"\nApp Store Connect users: {len(users)}")
    for user in users:
        attrs = user["attributes"]
        hide(attrs.get("username"))
        print(f"  - {mask_email(attrs.get('username', '?'))}  roles: {', '.join(attrs.get('roles', []))}")

    if email:
        hide(email)
        match = next((u for u in users if u["attributes"].get("username", "").lower() == email.lower()), None)
        attrs = match["attributes"] if match else {}
        return email, attrs.get("firstName", "Tester"), attrs.get("lastName", "Tester")

    holder = next((u for u in users if "ACCOUNT_HOLDER" in u["attributes"].get("roles", [])), None)
    holder = holder or next((u for u in users if "ADMIN" in u["attributes"].get("roles", [])), None)
    if not holder:
        return None, None, None
    attrs = holder["attributes"]
    return attrs["username"], attrs.get("firstName", "Tester"), attrs.get("lastName", "Tester")


def report(api, app_id):
    builds = latest_builds(api, app_id)
    print("\nLatest builds:")
    if not builds:
        print("  (none)")
    for b in builds:
        print(
            f"  - {b['version']} ({b['number']})  uploaded {b['uploaded']}  processing: {b['processing']}"
            f"  expired: {b['expired']}  encryption: {b['encryption']}"
            f"  internal: {b['internal']}  external: {b['external']}"
        )

    groups = api.get(f"/apps/{app_id}/betaGroups", limit=50)["data"]
    print(f"\nBeta groups: {len(groups)}")
    for group in groups:
        attrs = group["attributes"]
        testers = group_testers(api, group["id"])
        build_ids = group_build_ids(api, group["id"])
        print(
            f"  - {attrs.get('name')}  internal: {attrs.get('isInternalGroup')}"
            f"  all builds: {attrs.get('hasAccessToAllBuilds')}  builds: {len(build_ids)}"
            f"  public link: {attrs.get('publicLinkEnabled')}  testers: {len(testers)}"
        )
        for tester in testers:
            t = tester["attributes"]
            hide(t.get("email"))
            print(f"      - {mask_email(t.get('email') or '?')}  state: {t.get('state')}  invite: {t.get('inviteType')}")
    return builds, groups


def fix(api, app_id, builds, groups, email, first_name, last_name):
    failures = 0
    latest = builds[0] if builds else None
    usable = latest and latest["processing"] == "VALID" and not latest["expired"]

    if latest and latest["internal"] == "MISSING_EXPORT_COMPLIANCE":
        print(f"\nAnswering export compliance for build {latest['number']}.")
        api.patch(
            f"/builds/{latest['id']}",
            {"type": "builds", "id": latest["id"], "attributes": {"usesNonExemptEncryption": False}},
        )

    group = next((g for g in groups if g["attributes"].get("isInternalGroup")), None)
    if group:
        print(f"\nUsing the internal group \"{group['attributes'].get('name')}\".")
    else:
        print(f"\nCreating the internal group \"{GROUP_NAME}\" with access to all builds.")
        group = api.post(
            "/betaGroups",
            {
                "type": "betaGroups",
                "attributes": {"name": GROUP_NAME, "isInternalGroup": True, "hasAccessToAllBuilds": True},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            },
        )["data"]
    group_id = group["id"]

    if usable and not group["attributes"].get("hasAccessToAllBuilds"):
        if latest["id"] not in group_build_ids(api, group_id):
            print(f"Adding build {latest['number']} to the group.")
            api.post(f"/betaGroups/{group_id}/relationships/builds", [{"type": "builds", "id": latest["id"]}])

    if not email:
        print("No tester email found. Set the TESTER_EMAIL secret to your Apple ID email and run again.")
        return failures + 1

    testers = group_testers(api, group_id)
    tester = next((t for t in testers if (t["attributes"].get("email") or "").lower() == email.lower()), None)

    if tester is None:
        print(f"Adding {mask_email(email)} to the group. Apple sends the invitation email.")
        try:
            api.post(
                "/betaTesters",
                {
                    "type": "betaTesters",
                    "attributes": {"email": email, "firstName": first_name, "lastName": last_name},
                    "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": group_id}]}},
                },
            )
        except ApiError as error:
            if error.status != 409:
                print(f"Could not add the tester: {error}")
                return failures + 1
            existing = api.get("/betaTesters", **{"filter[email]": email})["data"]
            if not existing:
                print(f"Could not add the tester: {error}")
                return failures + 1
            api.post(f"/betaGroups/{group_id}/relationships/betaTesters", [{"type": "betaTesters", "id": existing[0]["id"]}])
            failures += send_invitation(api, app_id, existing[0]["id"], email)
    elif tester["attributes"].get("state") not in ACCEPTED_STATES:
        failures += send_invitation(api, app_id, tester["id"], email)
    else:
        print(f"{mask_email(email)} has already accepted. The build shows up in the TestFlight app.")

    return failures


def send_invitation(api, app_id, tester_id, email):
    print(f"Sending the TestFlight invitation to {mask_email(email)} again.")
    try:
        api.post(
            "/betaTesterInvitations",
            {
                "type": "betaTesterInvitations",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": app_id}},
                    "betaTester": {"data": {"type": "betaTesters", "id": tester_id}},
                },
            },
        )
    except ApiError as error:
        print(f"Could not send the invitation: {error}")
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--fix", action="store_true", help="fix what keeps builds from reaching testers")
    args = parser.parse_args()

    api = Api()
    app = find_app(api)
    app_id = app["id"]
    print(f"App: {app['attributes'].get('name')}  ({BUNDLE_ID}, Apple ID {app_id})")

    builds, groups = report(api, app_id)
    email, first_name, last_name = find_tester_email(api)
    print(f"\nTester to invite: {mask_email(email) if email else '(none found)'}")

    if not args.fix:
        return

    try:
        failures = fix(api, app_id, builds, groups, email, first_name, last_name)
    except ApiError as error:
        print(f"\nFix failed: {error}")
        failures = 1

    print("\nAfter the fixes:")
    report(api, app_id)
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
