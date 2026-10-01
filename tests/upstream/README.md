# 固定上游测试数据

这里仅收录 oracle/src/suite.rs 实际读取的 25 个 TOML 文件，保留上游目录结构和原始字节，不包含整个 Rust 仓库。抽样测试读取其中的子集。

来源与每个文件的 SHA-256 见 manifest.json。文件来自固定提交的 Git 对象，完整验收先校验文件清单、哈希和 docs/baseline.json 的版本。上游采用 MIT OR Apache-2.0，原文许可证随附；版权 Copyright (c) 2014 The Rust Project Developers。fowler 数据保留上游生成标记和测试名称。

这些文件只是考题；Rust 参照和 regex-test 驱动仍由 Cargo 按 oracle/Cargo.lock 从固定提交获取。首次完整验收需要联网，不需要手工克隆原始仓库。升级基线时须同时审查数据、清单、锁文件和差分行为，不要只改哈希。
