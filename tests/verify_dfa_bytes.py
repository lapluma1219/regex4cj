"""Dense, sparse, and hybrid DFA search over raw bytes, including invalid UTF-8.

The reported span is a byte offset. Match start still comes from the reverse
byte NFA. Unicode word boundaries stay rejected at construction.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def check(kind, hex_text, pattern):
    args = ("dfa-bytes", kind, hex_text, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("dfa-bytes-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("ff61", "a"),
    ("ff", "a"),
    ("ff", "."),
    ("ff6161", "a+"),
    ("ff62", "a|b"),
    ("6162", "ab"),
    ("", "a*"),
    ("e4b8ad", "中"),
    ("ff61", "^a"),
    ("ff61", "a$"),
    ("ff", "a*"),
    ("80e4b8ad", "中"),
]

def check_many(kind, hex_text, patterns):
    args = ("dfa-bytes-many", kind, hex_text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("dfa-bytes-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


def check_overlap(kind, hex_text, patterns):
    args = ("dfa-bytes-overlap", kind, hex_text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("dfa-bytes-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


many = [
    ("ff61", ("a", "b")),
    ("ff62", ("a", "b")),
    ("6162", ("ab", "a")),
    ("", ("a", "b")),
    ("ff", ("a", "b")),
    ("616263", ("b", "c", "bc")),
    ("e4b8ad", ("中", "a")),
    ("80e4b8ad", ("中", ".")),
]
overlap = [
    ("ff6162", ("a", "b")),
    ("6161", ("a", "a+")),
    ("", ("a*", "b")),
    ("6162", ("a", "b", "ab")),
    ("ff", ("a*", "b")),
    ("e4b8ad61", ("中", "a")),
]

def check_quit(kind, quit_hex, hex_text, pattern):
    args = ("dfa-bytes-quit", kind, quit_hex, hex_text, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("dfa-bytes-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


quits = [
    ("ff", "ff61", "a"),
    ("ff", "61ff", "a"),
    ("00", "610062", "a.b"),
    ("ff", "6162", "ab"),
    ("80", "80e4b8ad", "中"),
    ("ff", "6162ff", "ab"),
    ("0a", "610a62", "a.b"),
]

count = 0
for hex_text, pattern in cases:
    for kind in ("dense", "sparse", "hybrid"):
        check(kind, hex_text, pattern)
        count += 1
for hex_text, patterns in many:
    for kind in ("dense", "sparse"):
        check_many(kind, hex_text, patterns)
        count += 1
for hex_text, patterns in overlap:
    for kind in ("dense", "sparse"):
        check_overlap(kind, hex_text, patterns)
        count += 1
for quit_hex, hex_text, pattern in quits:
    for kind in ("dense", "sparse"):
        check_quit(kind, quit_hex, hex_text, pattern)
        count += 1

print(f"dfa bytes: {count} searches matched")
