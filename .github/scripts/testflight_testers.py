"""Checks the TestFlight side of the app in App Store Connect and fixes it.

It prints the latest builds, the beta groups and their testers, and the test
information that external testing needs. With --fix it also makes sure that:

- the latest build has its export compliance answer,
- an internal beta group exists and has the latest build,
- the account holder (or TESTER_EMAIL) is a tester in that group,
- a tester who has not accepted yet gets the invitation again.

With --public-link it sets up external testing with a public link:

- fills in the beta app description, feedback email, review contact and
  "What to Test" where they are empty,
- creates the external group "Public" and adds the latest build to it,
- submits the build for beta app review,
- turns on the group's public link.

Run it again after Apple approves the build if the link could not be turned
on yet.

The repo is public, so emails, the phone number and the public link are
masked in the log. Copy the link from App Store Connect.

Needs APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_IDENTIFIER and
APP_STORE_CONNECT_PRIVATE_KEY in the environment. --public-link also needs
REVIEW_CONTACT_PHONE (with the country code, such as +905551234567) unless the
review contact phone is already filled in.
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
PUBLIC_GROUP_NAME = "Public"
ACCEPTED_STATES = {"ACCEPTED", "INSTALLED"}
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")

# Testers see these two in the TestFlight app, so they are in Turkish (the
# app's primary locale) and follow the glossary in design-system/MASTER.md.
BETA_DESCRIPTION = (
    "1 Million Steps bir yürüyüş oyunu. Günlük adımların seni önce hazırlık "
    "kademelerinden, sonra Türkiye'nin dört bir yanındaki haftalık "
    "maratonlardan geçirir. Bitirdiğin yarışlar madalya ve coin kazandırır; "
    "coin ile hava ve zemine uygun ayakkabı ve eşofman takımı alırsın. Bu "
    "beta sürümünde adımlar gerçek değil: Yarış sekmesindeki test düğmeleriyle "
    "adım ekleyip ertesi güne geçebilirsin."
)
WHATS_NEW = (
    "İlk beta sürümü. Adımlar şimdilik gerçek değil. Yarış sekmesinde "
    "\"+5.000 adım\" ile adım ekle, \"Ertesi gün\" ile günü ilerlet; "
    "hazırlık kademelerini, maratonları ve mağazayı dene."
)
# Apple's reviewers read this one, so it is in English.
REVIEW_NOTES = (
    "No account or sign-in is needed. The app does not read health data yet "
    "and has no network features; steps are simulated. On the race tab, the "
    "floating test buttons (\"+5.000 adım\" and \"Ertesi gün\") add 5,000 "
    "steps or jump to the next day, so every screen can be reached without "
    "walking. The interface is in Turkish."
)


def mask_email(email):
    user, _, domain = email.partition("@")
    return f"{user[:1]}***@{domain}"


def mask_link(link):
    head, _, code = link.rpartition("/")
    return f"{head}/{code[:2]}***" if code else "***"


def scrub(text):
    return EMAIL_RE.sub(lambda m: mask_email(m.group(0)), str(text))


def hide(value):
    """Tells GitHub Actions to mask the value anywhere in the log."""
    if value:
        print(f"::add-mask::{value}")


def filled(value):
    return "set" if value else "EMPTY"


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
        link = attrs.get("publicLink")
        hide(link)
        print(
            f"  - {attrs.get('name')}  internal: {attrs.get('isInternalGroup')}"
            f"  all builds: {attrs.get('hasAccessToAllBuilds')}  builds: {len(build_ids)}"
            f"  public link: {attrs.get('publicLinkEnabled')} {mask_link(link) if link else ''}"
            f"  testers: {len(testers)}"
        )
        for tester in testers:
            t = tester["attributes"]
            hide(t.get("email"))
            print(f"      - {mask_email(t.get('email') or '?')}  state: {t.get('state')}  invite: {t.get('inviteType')}")
    return builds, groups


def test_info(api, app_id, build):
    """Returns the beta app localizations, the review detail and the build's localizations."""
    localizations = api.get(f"/apps/{app_id}/betaAppLocalizations", limit=50)["data"]
    detail = api.get(f"/apps/{app_id}/betaAppReviewDetail")["data"]
    build_localizations = api.get(f"/builds/{build['id']}/betaBuildLocalizations", limit=50)["data"] if build else []
    return localizations, detail, build_localizations


def report_test_info(api, app, build):
    localizations, detail, build_localizations = test_info(api, app["id"], build)
    print(f"\nTest information (primary locale {app['attributes'].get('primaryLocale')}):")
    if not localizations:
        print("  - beta app description: none")
    for loc in localizations:
        a = loc["attributes"]
        print(
            f"  - {a.get('locale')}: description {filled(a.get('description'))}"
            f"  feedback email {filled(a.get('feedbackEmail'))}  privacy policy {filled(a.get('privacyPolicyUrl'))}"
        )
    d = detail["attributes"]
    hide(d.get("contactEmail"))
    hide(d.get("contactPhone"))
    print(
        f"  - review contact: name {filled(d.get('contactFirstName') and d.get('contactLastName'))}"
        f"  email {filled(d.get('contactEmail'))}  phone {filled(d.get('contactPhone'))}"
        f"  demo account required: {d.get('demoAccountRequired')}  notes {filled(d.get('notes'))}"
    )
    whats_new = any(b["attributes"].get("whatsNew") for b in build_localizations)
    print(f"  - What to Test for the latest build: {filled(whats_new)}")
    return localizations, detail, build_localizations


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


def set_up_public_link(api, app, builds, groups, info, email, first_name, last_name):
    app_id = app["id"]
    locale = app["attributes"].get("primaryLocale") or "en-US"
    localizations, detail, build_localizations = info
    latest = builds[0] if builds else None

    if not latest or latest["processing"] != "VALID" or latest["expired"]:
        print("\nThe latest build is not ready for testing. Upload a new build first.")
        return 1

    d = detail["attributes"]
    phone = os.environ.get("REVIEW_CONTACT_PHONE", "").strip().replace(" ", "")
    hide(phone)
    if not d.get("contactPhone") and not phone:
        print(
            "\nBeta app review needs a contact phone number. Set the REVIEW_CONTACT_PHONE secret"
            " (with the country code, such as +905551234567) and run again."
        )
        return 1
    if not email:
        print("\nNo email found for the feedback address and review contact. Set the TESTER_EMAIL secret.")
        return 1

    print("\nSetting up external testing with a public link.")

    loc = next((l for l in localizations if l["attributes"].get("locale") == locale), None)
    loc = loc or (localizations[0] if localizations else None)
    if loc is None:
        print(f"Adding the beta app description and feedback email ({locale}).")
        api.post(
            "/betaAppLocalizations",
            {
                "type": "betaAppLocalizations",
                "attributes": {"locale": locale, "description": BETA_DESCRIPTION, "feedbackEmail": email},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            },
        )
    else:
        wanted = {}
        if not loc["attributes"].get("description"):
            wanted["description"] = BETA_DESCRIPTION
        if not loc["attributes"].get("feedbackEmail"):
            wanted["feedbackEmail"] = email
        if wanted:
            print(f"Filling in the beta app {' and '.join(wanted)} ({loc['attributes'].get('locale')}).")
            api.patch(
                f"/betaAppLocalizations/{loc['id']}",
                {"type": "betaAppLocalizations", "id": loc["id"], "attributes": wanted},
            )

    wanted = {}
    if not d.get("contactFirstName"):
        wanted["contactFirstName"] = first_name
    if not d.get("contactLastName"):
        wanted["contactLastName"] = last_name
    if not d.get("contactEmail"):
        wanted["contactEmail"] = email
    if not d.get("contactPhone"):
        wanted["contactPhone"] = phone
    if d.get("demoAccountRequired") is None:
        wanted["demoAccountRequired"] = False
    if not d.get("notes"):
        wanted["notes"] = REVIEW_NOTES
    if wanted:
        print(f"Filling in the review information: {', '.join(wanted)}.")
        api.patch(
            f"/betaAppReviewDetails/{detail['id']}",
            {"type": "betaAppReviewDetails", "id": detail["id"], "attributes": wanted},
        )

    if not any(b["attributes"].get("whatsNew") for b in build_localizations):
        print(f"Adding What to Test for build {latest['number']}.")
        if build_localizations:
            first = build_localizations[0]
            api.patch(
                f"/betaBuildLocalizations/{first['id']}",
                {"type": "betaBuildLocalizations", "id": first["id"], "attributes": {"whatsNew": WHATS_NEW}},
            )
        else:
            api.post(
                "/betaBuildLocalizations",
                {
                    "type": "betaBuildLocalizations",
                    "attributes": {"locale": locale, "whatsNew": WHATS_NEW},
                    "relationships": {"build": {"data": {"type": "builds", "id": latest["id"]}}},
                },
            )

    external = [g for g in groups if not g["attributes"].get("isInternalGroup")]
    group = next((g for g in external if g["attributes"].get("name") == PUBLIC_GROUP_NAME), None)
    group = group or (external[0] if external else None)
    if group:
        print(f"Using the external group \"{group['attributes'].get('name')}\".")
    else:
        print(f"Creating the external group \"{PUBLIC_GROUP_NAME}\".")
        group = api.post(
            "/betaGroups",
            {
                "type": "betaGroups",
                "attributes": {"name": PUBLIC_GROUP_NAME, "feedbackEnabled": True},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            },
        )["data"]
    group_id = group["id"]

    if latest["id"] not in group_build_ids(api, group_id):
        print(f"Adding build {latest['number']} to the group.")
        api.post(f"/betaGroups/{group_id}/relationships/builds", [{"type": "builds", "id": latest["id"]}])

    failures = 0
    state = latest_builds(api, app_id)[0]["external"]
    if state == "READY_FOR_BETA_SUBMISSION":
        print(f"Submitting build {latest['number']} for beta app review.")
        try:
            api.post(
                "/betaAppReviewSubmissions",
                {
                    "type": "betaAppReviewSubmissions",
                    "relationships": {"build": {"data": {"type": "builds", "id": latest["id"]}}},
                },
            )
        except ApiError as error:
            print(f"Could not submit for review: {error}")
            failures += 1
    elif state in ("WAITING_FOR_BETA_REVIEW", "IN_BETA_REVIEW"):
        print(f"Build {latest['number']} is in beta app review ({state}).")
    elif state == "BETA_REJECTED":
        print(f"Apple rejected build {latest['number']} in beta app review. The reason is in App Store Connect.")
        failures += 1
    else:
        print(f"Build {latest['number']} external state: {state}.")

    if not group["attributes"].get("publicLinkEnabled"):
        print("Turning on the public link.")
        try:
            api.patch(
                f"/betaGroups/{group_id}",
                {
                    "type": "betaGroups",
                    "id": group_id,
                    "attributes": {"publicLinkEnabled": True, "publicLinkLimitEnabled": False},
                },
            )
        except ApiError as error:
            print(f"Could not turn on the public link yet: {error}")
            print("Run this again after Apple approves the build.")

    group = api.get(f"/betaGroups/{group_id}")["data"]
    link = group["attributes"].get("publicLink")
    hide(link)
    if link:
        print(
            f"Public link: {mask_link(link)} (masked). Copy it from App Store Connect: TestFlight,"
            f" the \"{group['attributes'].get('name')}\" group, Public Link."
        )
    return failures


def run(step, *args):
    try:
        return step(*args)
    except ApiError as error:
        print(f"\nFailed: {error}")
        return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--fix", action="store_true", help="fix what keeps builds from reaching internal testers")
    parser.add_argument("--public-link", action="store_true", help="set up external testing with a public link")
    args = parser.parse_args()

    api = Api()
    app = find_app(api)
    app_id = app["id"]
    print(f"App: {app['attributes'].get('name')}  ({BUNDLE_ID}, Apple ID {app_id})")

    builds, groups = report(api, app_id)
    email, first_name, last_name = find_tester_email(api)
    print(f"\nTester to invite: {mask_email(email) if email else '(none found)'}")
    info = report_test_info(api, app, builds[0] if builds else None)

    failures = 0
    if args.fix:
        failures += run(fix, api, app_id, builds, groups, email, first_name, last_name)
    if args.public_link:
        failures += run(set_up_public_link, api, app, builds, groups, info, email, first_name, last_name)

    if args.fix or args.public_link:
        print("\nAfterwards:")
        builds, _ = report(api, app_id)
        report_test_info(api, app, builds[0] if builds else None)
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
