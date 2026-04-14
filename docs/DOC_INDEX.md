# DOC_INDEX.md

项目文档系统统一入口。

---

## 游戏设计文档（`design/gdd/`）

面向 agent 的权威设计参考，定义所有游戏机制和系统规格。系统索引见 [`design/gdd/systems-index.md`](../design/gdd/systems-index.md)。

| 文件 | 说明 |
|------|------|
| [`design/gdd/systems-index.md`](../design/gdd/systems-index.md) | 所有 GDD 系统索引 |
| [`design/gdd/towers.md`](../design/gdd/towers.md) | 4 座塔的完整规格（firing_rate、炮管数、初始弹药、命名规则） |
| [`design/gdd/modules.md`](../design/gdd/modules.md) | 14 个模块的完整规格，分 3 类（COMPUTATIONAL / LOGICAL / SPECIAL） |
| [`design/gdd/effects.md`](../design/gdd/effects.md) | 效果系统接口文档（BulletEffect / TowerEffect / FireEffect） |
| [`design/gdd/effect-matrix.md`](../design/gdd/effect-matrix.md) | 触发时机 × 触发效果矩阵 |
| [`design/gdd/shadow-tower.md`](../design/gdd/shadow-tower.md) | 影子炮塔系统完整参考 |
| [`design/gdd/shield-enemy.md`](../design/gdd/shield-enemy.md) | 护盾敌人系统 |
| [`design/gdd/variants.md`](../design/gdd/variants.md) | 炮塔变体系统 |
| [`design/gdd/item-pool.md`](../design/gdd/item-pool.md) | Item Pool — 统一 tower/module 注册表 |

---

## 技术架构文档（`docs/architecture/`）

ADR（架构决策记录）存放于此。使用 `/architecture-decision` 创建新 ADR。

*暂无 ADR — 使用 `/architecture-decision` 创建第一个。*

---

## 测试文档（`docs/tests/`）

| 文件 | 说明 |
|------|------|
| [`tests/HOW_TO_RUN_TESTS.md`](tests/HOW_TO_RUN_TESTS.md) | 如何运行 GdUnit4 测试，测试套件概览 |
| [`tests/gdunit_testing.md`](tests/gdunit_testing.md) | GdUnit4 测试框架详细文档 |

---

## 开发计划（`docs/superpowers/plans/`）

| 文件 | 说明 |
|------|------|
| [`superpowers/plans/2026-04-14-ccgs-migration.md`](superpowers/plans/2026-04-14-ccgs-migration.md) | CCGS 目录结构迁移实施计划 |
| [`superpowers/plans/2026-04-02-tower-module-test-framework.md`](superpowers/plans/2026-04-02-tower-module-test-framework.md) | Tower/Module 测试框架实施计划（已完成） |

---

## 过时文档（`docs/outdated/`）

| 文件 | 说明 |
|------|------|
| [`outdated/DESIGN_V1.0.md`](outdated/DESIGN_V1.0.md) | v1.0 模块/遗物设计文档 |
| [`outdated/DEVELOPER.md`](outdated/DEVELOPER.md) | 旧版架构和算法深入文档 |
| [`outdated/EFFECT_SYSTEM.md`](outdated/EFFECT_SYSTEM.md) | 旧版效果系统文档 |
| [`outdated/IMPLEMENTATION_PLAN.md`](outdated/IMPLEMENTATION_PLAN.md) | 旧版开发路线图 |
