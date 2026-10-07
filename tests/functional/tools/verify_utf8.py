"""UTF-8 scalar ranges against regex-syntax Utf8Sequences."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(start, end):
    args = ("utf8", str(start), str(end))
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("utf8-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


ranges = [
    (0, 0),
    (0, 127),
    (128, 128),
    (128, 2047),
    (2048, 2048),
    (0xD7FF, 0xE000),
    (0x0800, 0xFFFF),
    (0x10000, 0x10000),
    (0x10000, 0x10FFFF),
    (0, 0x10FFFF),
    (0x20, 0x7E),
    (0x4E00, 0x4E10),
]

for start, end in ranges:
    compare(start, end)

for bad in [(0xD800, 0xD800), (0xDFFF, 0xDFFF), (10, 9), (0x110000, 0x110000)]:
    rust, cj = run(RUST, "utf8", str(bad[0]), str(bad[1])), run(CJ, "utf8", str(bad[0]), str(bad[1]))
    if rust.returncode == 0 or cj.returncode == 0:
        raise AssertionError(dict(bad=bad, rust_code=rust.returncode, cangjie_code=cj.returncode))

print(f"utf8 sequences: {len(ranges)} ranges")
