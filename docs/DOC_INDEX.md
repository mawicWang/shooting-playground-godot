# DOC_INDEX.md

本文档是 `docs/` 目录的统一入口。

## 游戏内容知识库（`content/`）

面向 agent 的权威参考源，定义游戏中所有可配置内容的规格。测试和实现应对齐这些文件。

| 文件 | 说明 |
|------|------|
| [`content/towers.md`](content/towers.md) | 4 座塔的完整规格（firing_rate、炮管数、初始弹药、命名规则） |
| [`content/modules.md`](content/modules.md) | 14 个模块的完整规格，分 3 类（COMPUTATIONAL / LOGICAL / SPECIAL），含预期行为、测试位置 |
| [`content/effects.md`](content/effects.md) | 效果系统接口文档（BulletEffect / TowerEffect / FireEffect），含 MockTower 接口和新增效果流程 |
| [`content/effect-matrix.md`](content/effect-matrix.md) | 触发时机 × 触发效果矩阵，标注已实现（✅）与未实现（❌）组合 |
| [`content/shadow-tower.md`](content/shadow-tower.md) | 影子炮塔系统完整参考：碰撞层、team 隔离、共享 Effect 陷阱、生成深度控制、生命周期 |

## 测试文档（`tests/`）

| 文件 | 说明 |
|------|------|
| [`tests/HOW_TO_RUN_TESTS.md`](tests/HOW_TO_RUN_TESTS.md) | 如何运行 GdUnit4 测试（编辑器方式和命令行方式），测试套件概览，MockTower 说明 |
| [`tests/gdunit_testing.md`](tests/gdunit_testing.md) | GdUnit4 测试框架详细文档：测试覆盖详情、断言速查、编写新测试模板、生命周期钩子 |

## 开发计划（`superpowers/plans/`）

| 文件 | 说明 |
|------|------|
| [`superpowers/plans/2026-04-02-tower-module-test-framework.md`](superpowers/plans/2026-04-02-tower-module-test-framework.md) | Tower/Module 测试框架实施计划（已完成） |

## 过时文档（`outdated/`）

以下文档来自原 `doc/` 目录，已标记为过时，仅供参考历史上下文。

| 文件 | 说明 |
|------|------|
| [`outdated/DESIGN_V1.0.md`](outdated/DESIGN_V1.0.md) | v1.0 模块/遗物设计文档 |
| [`outdated/DEVELOPER.md`](outdated/DEVELOPER.md) | 旧版架构和算法深入文档 |
| [`outdated/EFFECT_SYSTEM.md`](outdated/EFFECT_SYSTEM.md) | 旧版效果系统文档 |
| [`outdated/IMPLEMENTATION_PLAN.md`](outdated/IMPLEMENTATION_PLAN.md) | 旧版开发路线图 |
