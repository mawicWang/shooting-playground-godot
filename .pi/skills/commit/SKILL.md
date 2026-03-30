---
name: commit
description: 执行 commit checklist：检查 git status、确认无功能删除、运行 build、写中文 commit message、push。使用 /skill:commit 触发。
---

# Commit Checklist

执行以下步骤完成代码提交：

## 1. 检查 Git 状态

```bash
git status
```

确认所有修改的文件都已 staged。如有未 staged 的文件，询问用户是否需要 add。

## 2. 检查功能完整性

查看 diff，确认没有误删 previously working features。

## 3. 运行 Build（如适用）

对于 Godot 项目：
```bash
./build_web.sh
```

如果 build 失败，停止并报告错误。

## 4. 编写 Commit Message

用中文写简洁的 commit message，格式：
- `feat: 新功能描述`
- `fix: 修复描述`
- `refactor: 重构描述`
- `chore: 杂项描述`

## 5. Push

```bash
git push
```

## 执行流程

按顺序执行 1-5，每步通过后继续。遇到问题停止并询问用户。