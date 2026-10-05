# 赛事要求与交付状态

依据先前保存的官方规则摘录整理。2026-10-05重新读取赛事网页失败，以下不代表已核实当天最新规则；命题资料包、具体模板和平台要求仍以官方为准。这里是要求清单，执行顺序统一见[交付计划](delivery-plan.md)。

来源：[赛事介绍](https://competitions.atomgit.com/competition/2090379383571447809/intro)、[1.1.3下载](https://cangjie-lang.cn/download/1.1.3)、[中心仓制品规格](https://pkgdocs.cangjie-lang.cn/docs/zh/1.0.0/central-repo/source_zh_cn/artifact.html)、[制品发布](https://pkgdocs.cangjie-lang.cn/docs/zh/1.0.0/central-repo/source_zh_cn/client/upload.html)。

| 要求类别 | 已记录要求 | 当前状态 |
|---|---|---|
| SDK | 适配STS Cangjie1.1.3 | 三个模块清单为1.1.3，实际使用该编译器验证；平台范围见status |
| 源码 | 代码、README、LICENSE、README.OpenSource、CHANGELOG和测试 | 仓库及模块已有说明/许可；README.OpenSource需对照官方具体模板 |
| 中心仓 | 适配后按规范提交 | 本机bundle及解压后独立消费者通过；中心仓安装/发布尚未完成，见status |
| 作品平台 | AtomGit报名、作品仓库及指定同步流程 | 本地GitHub仓库不能代替，需核对实际报名与登录后流程 |
| 视频与模板 | 可访问的演示视频、统一模板及签字PDF | 视频由用户安排；未以代码测试代替材料完成 |
| 功能说明 | 说明未实现部分及其比例/重要程度 | status及范围台账已明示，不宣称实测80% |
| 版本 | 初赛固定版本、决赛迭代说明 | 应保留候选提交/标签，不能用后续测试证明较早版本 |

先前规则记录：初赛截止10月7日23:59:59，最终版本10月23日23:59:59，均为北京时间；提交前必须再次确认官方时间与赛题要求。选题是否要求整个Rust workspace、评测OS/CPU、中心仓具体时限及模板收件方式仍须官方确认，不能自行假定。

`cjpm bundle`只打包模块目录，`port/`之外的测试不会自动进入包。当前模块名/根包名是cjregex，仓库名是regex4cj。包验证应覆盖README/许可证、元信息、编译/测试/lint及实际消费；发布所需账号和令牌不得提交到仓库。
