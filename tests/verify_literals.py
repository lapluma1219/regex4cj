"""Prefix and suffix literal extraction against regex-syntax Extractor defaults."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(kind, pattern):
    args = ("literals", kind, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


patterns = [
    "abc",
    "foo|bar",
    "ab*c",
    "a*",
    "a*?",
    "a+",
    "a?",
    "a??",
    "a{3}",
    "a{10}",
    "a{11}",
    "a{3,5}",
    "a{0}",
    "a+b",
    "foo(bar|baz)",
    "^abc",
    "abc$",
    ".",
    r"\d",
    "[abc]",
    "[a-c]",
    "[a-j]",
    "[a-k]",
    "中",
    "[中]",
    "(?-u:[a-c])",
    "a" * 150,
    "|".join(f"x{i}" for i in range(250)),
    "|".join(f"x{i}" for i in range(251)),
    r"[a&&b]",
    "(?:ab){2}",
    "sam|samwise",
]

for pattern in patterns:
    compare("prefix", pattern)
    compare("suffix", pattern)


def compare_config(limits, kind, pattern):
    args = ("literals-config", *limits, kind, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


configs = [
    (("2", "10", "100", "250"), "prefix", "[abc]"),
    (("10", "10", "100", "250"), "prefix", "[abc]"),
    (("10", "3", "100", "250"), "prefix", "a{10}"),
    (("10", "10", "3", "250"), "prefix", "abcdef"),
    (("10", "10", "100", "4"), "prefix", "ab|cd|ef|gh"),
    (("10", "10", "100", "4"), "suffix", "ab|cd|ef|gh"),
    (("5", "5", "20", "30"), "prefix", "(abc){8}"),
]
for limits, kind, pattern in configs:
    compare_config(limits, kind, pattern)


def piece(exact, text):
    tag = "E" if exact else "I"
    return f"{tag}:{text.encode().hex()}"


def seq(*parts):
    return ",".join(parts)


def compare_op(*args):
    full = ("literal-op",) + args
    rust, cj = run(RUST, *full), run(CJ, *full)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=full, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


foo_bar = seq(piece(True, "foo"), piece(False, "bar"))
quux_baz = seq(piece(False, "quux"), piece(True, "baz"))
operations = [
    ("cross-forward", foo_bar, quux_baz),
    ("cross-reverse", foo_bar, quux_baz),
    ("cross-forward", foo_bar, "inf"),
    ("cross-forward", seq(piece(True, "foo"), piece(True, ""), piece(False, "bar")), "inf"),
    ("cross-forward", "inf", foo_bar),
    ("cross-forward", "empty", piece(True, "foo")),
    ("union", seq(piece(True, "foo"), piece(True, "bar")), seq(piece(True, "bar"), piece(True, "quux"), piece(True, "foo"))),
    ("union", "inf", seq(piece(True, "bar"), piece(True, "quux"), piece(True, "foo"))),
    ("union-empty", seq(piece(True, "a"), piece(True, ""), piece(True, "f"), piece(True, "")), piece(True, "foo")),
    ("union-empty", seq(piece(True, "foo"), piece(True, "bar")), seq(piece(True, "bar"), piece(True, "quux"))),
    ("union-empty", seq(piece(True, "a"), piece(True, "")), "inf"),
    ("keep-first", "2", seq(piece(True, "a"), piece(True, "foo"), piece(True, "quux"))),
    ("keep-last", "2", seq(piece(True, "a"), piece(True, "foo"), piece(True, "quux"))),
    ("minimize", seq(piece(True, "sam"), piece(True, "samwise"))),
    ("minimize", seq(piece(True, "samwise"), piece(True, "sam"))),
    ("minimize", seq(piece(True, "foo"), piece(True, "bar"), piece(True, ""), piece(True, "quux"), piece(True, "fox"))),
    ("minimize", seq(piece(True, ""), piece(True, "foo"), piece(True, "quux"))),
    ("reverse", seq(piece(True, "oof"), piece(True, "rab"))),
    ("sort", seq(piece(True, "foo"), piece(True, "quux"), piece(True, "bar"))),
    ("sort", seq(piece(True, "foo"), piece(False, "foo"), piece(True, "a"))),
    ("dedup", seq(piece(True, "foo"), piece(False, "foo"))),
    ("dedup", seq(piece(True, "foo"), piece(True, "foo"), piece(True, "bar"))),
    ("inexact", foo_bar),
    ("prefix", seq(piece(True, "foo"), piece(True, "foobar"), piece(True, "fo"))),
    ("prefix", seq(piece(True, "foo"), piece(True, "bar"))),
    ("prefix", piece(True, "")),
    ("prefix", "inf"),
    ("prefix", "empty"),
    ("suffix", seq(piece(True, "oof"), piece(True, "raboof"), piece(True, "of"))),
    ("suffix", seq(piece(True, "foo"), piece(True, "foo"))),
    ("suffix", seq(piece(True, "foo"), piece(True, "bar"))),
    ("suffix", piece(True, "")),
    ("suffix", "inf"),
    ("suffix", "empty"),
    ("finite", foo_bar),
    ("finite", "inf"),
    ("empty", "empty"),
    ("empty", foo_bar),
    ("exact", seq(piece(True, "foo"), piece(True, "bar"))),
    ("exact", foo_bar),
    ("exact", "empty"),
    ("exact", "inf"),
    ("inexact-all", foo_bar),
    ("inexact-all", "inf"),
    ("inexact-all", "empty"),
    ("len", foo_bar),
    ("len", "inf"),
    ("len", "empty"),
    ("min-len", seq(piece(True, "a"), piece(True, "foo"))),
    ("min-len", "inf"),
    ("min-len", "empty"),
    ("max-len", seq(piece(True, "a"), piece(True, "foo"))),
    ("max-len", "empty"),
    ("pipe", "keep-first:3|minimize", seq(
        piece(True, "farm"), piece(True, "appliance"), piece(True, "faraway"), piece(True, "apple"),
        piece(True, "fare"), piece(True, "gap"), piece(True, "applicant"), piece(True, "applaud"),
    )),
    ("optimize-prefix", seq(piece(True, "samantha"), piece(True, "sam"), piece(True, "samwise"), piece(True, "frodo"))),
    ("optimize-prefix", seq(piece(True, "samantha"), piece(True, ""), piece(True, "sam"), piece(True, "samwise"), piece(True, "frodo"))),
    ("optimize-prefix", seq(piece(True, "samantha"), piece(True, " "), piece(True, "sam"), piece(True, "frodo"))),
    ("optimize-prefix", seq(piece(True, "Qabcde"), piece(True, "Qabxyz"))),
    ("optimize-prefix", seq(*(piece(True, "hello" + chr(65 + i)) for i in range(12)))),
    ("optimize-prefix", seq(*(piece(True, f"item{i:02d}xxxx") for i in range(20)))),
    ("optimize-prefix", "inf"),
    ("optimize-prefix", "empty"),
    ("optimize-suffix", seq(piece(True, "oof"), piece(True, "raboof"), piece(True, "of"))),
    ("optimize-suffix", seq(piece(False, "xxhello"), piece(False, "yyhello"), piece(False, "zzhello"))),
    ("optimize-suffix", seq(piece(True, "samantha"), piece(True, ""), piece(True, "frodo"))),
    ("pipe", "optimize-prefix", seq(piece(True, "sam"), piece(True, "samwise"))),
    ("max-union", foo_bar, quux_baz),
    ("max-union", "inf", foo_bar),
    ("max-union", foo_bar, "inf"),
    ("max-union", "empty", foo_bar),
    ("max-cross", foo_bar, quux_baz),
    ("max-cross", "inf", foo_bar),
    ("max-cross", "empty", foo_bar),
    ("max-cross", seq(piece(True, "a"), piece(True, "b"), piece(True, "c")), seq(piece(True, "x"), piece(True, "y"))),
]
for op in operations:
    compare_op(*op)


def parse_seq(stdout):
    text = stdout.replace("\r\n", "\n").strip("\n")
    if text == "infinite":
        return None
    lines = text.splitlines()
    pieces = []
    for line in lines[1:]:
        tag, hex_bytes = line.split("\t", 1)
        pieces.append((tag == "exact", bytes.fromhex(hex_bytes)))
    return pieces


def covers(kind, pieces, span):
    if pieces is None:
        return True
    for exact, literal in pieces:
        aligned = span.endswith(literal) if kind == "suffix" else span.startswith(literal)
        if aligned and (not exact or len(span) == len(literal)):
            return True
    return False


filters = [
    ("abc", "xxabcxx"),
    ("foo|bar", "bar"),
    ("a+", "aaab"),
    ("sam|samwise", "samwise sam"),
    ("^abc", "abc"),
    ("abc$", "zzabc"),
    ("ab*c", "abbbcac"),
    ("foo(bar|baz)", "foobaz"),
    ("[abc]", "b"),
    ("a{3}", "aaa"),
    (r"\d", "9"),
    ("中", "x中"),
    ("a|ab", "ab"),
    ("a*", "b"),
    (".", "中"),
    ("(?:ab){2}", "abab"),
]
covered = 0
for pattern, text in filters:
    for kind in ("prefix", "suffix"):
        args = ("literals", kind, pattern)
        rust, cj = run(RUST, *args), run(CJ, *args)
        if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
            failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                           rust_error=rust.stderr, cangjie_error=cj.stderr)
            REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
            raise AssertionError(failure)
        found = run(RUST, "find", pattern, text)
        mirrored = run(CJ, "find", pattern, text)
        if found.returncode or mirrored.returncode or found.stdout != mirrored.stdout:
            failure = dict(pattern=pattern, text=text, rust=found.stdout, cangjie=mirrored.stdout,
                           rust_error=found.stderr, cangjie_error=mirrored.stderr)
            REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
            raise AssertionError(failure)
        pieces = parse_seq(cj.stdout)
        hay = text.encode()
        for line in found.stdout.splitlines():
            start, end, _match = line.split("\t", 2)
            span = hay[int(start):int(end)]
            if not covers(kind, pieces, span):
                failure = dict(pattern=pattern, text=text, kind=kind, span=span.hex(), literals=cj.stdout)
                REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
                raise AssertionError(failure)
            covered += 1

print(
    f"literal extraction: {len(patterns)} patterns, prefix and suffix, {len(configs)} configured, "
    f"{len(operations)} sequence operations, {covered} filter spans"
)
