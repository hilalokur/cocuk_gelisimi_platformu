import json
import re
import urllib.request
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "lib" / "utils" / "who_growth_standards.dart"

URLS = {
    "height": {
        "female": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lhfa_girls_0-to-2-years_zscores.xlsx",
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lhfa_girls_2-to-5-years_zscores.xlsx",
        ],
        "male": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lhfa_boys_0-to-2-years_zscores.xlsx",
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/length-height-for-age/lhfa_boys_2-to-5-years_zscores.xlsx",
        ],
    },
    "weight": {
        "female": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa_girls_0-to-5-years_zscores.xlsx",
        ],
        "male": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/weight-for-age/wfa_boys_0-to-5-years_zscores.xlsx",
        ],
    },
    "head": {
        "female": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/head-circumference-for-age/hcfa-girls-0-5-zscores.xlsx",
        ],
        "male": [
            "https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/head-circumference-for-age/hcfa-boys-0-5-zscores.xlsx",
        ],
    },
}


def col_to_index(cell_ref: str) -> int:
    letters = re.match(r"[A-Z]+", cell_ref).group(0)
    idx = 0
    for ch in letters:
        idx = idx * 26 + ord(ch) - ord("A") + 1
    return idx - 1


def read_xlsx_rows(url: str) -> list[list[str]]:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 WHO growth standards data fetcher",
        },
    )
    with urllib.request.urlopen(request, timeout=45) as response:
        data = response.read()

    from io import BytesIO

    with zipfile.ZipFile(BytesIO(data)) as zf:
        shared = []
        if "xl/sharedStrings.xml" in zf.namelist():
            root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
            ns = {"x": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
            for si in root.findall("x:si", ns):
                shared.append("".join(t.text or "" for t in si.findall(".//x:t", ns)))

        sheet_name = "xl/worksheets/sheet1.xml"
        root = ET.fromstring(zf.read(sheet_name))
        ns = {"x": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
        rows = []
        for row in root.findall(".//x:sheetData/x:row", ns):
            values = []
            for cell in row.findall("x:c", ns):
                idx = col_to_index(cell.attrib["r"])
                while len(values) < idx:
                    values.append("")
                value = cell.find("x:v", ns)
                text = "" if value is None else value.text or ""
                if cell.attrib.get("t") == "s" and text:
                    text = shared[int(text)]
                values.append(text)
            rows.append(values)
        return rows


def normalize_header(value: str) -> str:
    value = value.strip().lower().replace(" ", "")
    aliases = {
        "month": "age",
        "months": "age",
        "l": "l",
        "m": "m",
        "s": "s",
        "-3sd": "sd3neg",
        "-2sd": "sd2neg",
        "-1sd": "sd1neg",
        "median": "sd0",
        "0sd": "sd0",
        "1sd": "sd1",
        "+1sd": "sd1",
        "2sd": "sd2",
        "+2sd": "sd2",
        "3sd": "sd3",
        "+3sd": "sd3",
    }
    return aliases.get(value, value)


def parse_table(url: str) -> list[dict[str, float]]:
    rows = read_xlsx_rows(url)
    header_index = None
    headers = []
    for i, row in enumerate(rows):
        normalized = [normalize_header(str(v)) for v in row]
        if "age" in normalized and "sd0" in normalized and "sd3neg" in normalized:
            header_index = i
            headers = normalized
            break

    if header_index is None:
        raise RuntimeError(f"Could not find header in {url}")

    required = [
        "age",
        "l",
        "m",
        "s",
        "sd3neg",
        "sd2neg",
        "sd1neg",
        "sd0",
        "sd1",
        "sd2",
        "sd3",
    ]
    indexes = {key: headers.index(key) for key in required}
    parsed = []
    for row in rows[header_index + 1 :]:
        if len(row) <= indexes["age"] or not str(row[indexes["age"]]).strip():
            continue
        try:
            item = {key: float(row[idx]) for key, idx in indexes.items()}
        except (ValueError, IndexError):
            continue
        parsed.append(item)
    return parsed


def merge_tables(urls: list[str]) -> list[dict[str, float]]:
    by_age = {}
    for url in urls:
        for item in parse_table(url):
            age = int(round(item.pop("age")))
            by_age[age] = item
    return [dict(age=age, **by_age[age]) for age in sorted(by_age)]


def dart_number(value: float) -> str:
    return f"{value:.4f}".rstrip("0").rstrip(".")


def dart_rows(rows: list[dict[str, float]]) -> str:
    parts = []
    for row in rows:
        values = [
            int(row["age"]),
            row["l"],
            row["m"],
            row["s"],
            row["sd3neg"],
            row["sd2neg"],
            row["sd1neg"],
            row["sd0"],
            row["sd1"],
            row["sd2"],
            row["sd3"],
        ]
        parts.append("[" + ", ".join(str(v) if isinstance(v, int) else dart_number(v) for v in values) + "]")
    return "[\n    " + ",\n    ".join(parts) + "\n  ]"


def main() -> None:
    data = {
        measure: {
            gender: merge_tables(urls)
            for gender, urls in genders.items()
        }
        for measure, genders in URLS.items()
    }
    source_json = json.dumps(URLS, indent=2)
    content = [
        "// ignore_for_file: constant_identifier_names",
        "",
        "// Generated from official WHO Child Growth Standards z-score tables.",
        "// Source URLs:",
        *["// " + line for line in source_json.splitlines()],
        "",
        "class WhoGrowthStandards {",
        "  static const columns = ['age', 'L', 'M', 'S', '-3SD', '-2SD', '-1SD', 'median', '+1SD', '+2SD', '+3SD'];",
        "",
    ]
    for measure, genders in data.items():
        for gender, rows in genders.items():
            content.append(f"  static const {measure}_{gender} = {dart_rows(rows)};")
            content.append("")
    content.append("}")
    OUT.write_text("\n".join(content) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
