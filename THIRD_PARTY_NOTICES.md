# Third-party notices

The functions `escape` and `isMetaCharacter` in `port/src/main.cj` are adapted
from `regex-syntax/src/lib.rs` in https://github.com/rust-lang/regex,
commit `72d650cb0a880a01ab6dc2137c0888e8f89740f7`.

The Thompson construction, ordered NFA simulation and empty-match iteration in
`port/src/nfa.cj` are adapted from the same commit's
`regex-automata/src/nfa/thompson/compiler.rs`, `pikevm.rs` and `util/iter.rs`.
`port/src/parser.cj` is a new restricted syntax adapter, not a translation of the
complete upstream parser. Character class and repetition behavior additionally
follows `regex-syntax/src/ast/parse.rs`; `port/src/charset.cj` adapts the interval-set
semantics of `regex-syntax/src/hir/interval.rs` to Cangjie, without its generic
in-place implementation or case-folding support. See `docs/milestone-1.md` and `docs/milestone-2.md` for symbol-level provenance.

Copyright (c) 2014 The Rust Project Developers.

Upstream is licensed under MIT OR Apache-2.0. Both original license texts are
included as LICENSE-MIT and LICENSE-APACHE. The translated code retains this
attribution. Original project code is also provided under MIT OR Apache-2.0.

The Rust oracle resolves the original repository as a pinned Git dependency;
its source and other dependencies are not vendored here. Reference tools and
corpora (CangjieSkills, CangjieCorpus) and SDK distributions are local development
resources, not included in this repository and not relicensed by this project.
