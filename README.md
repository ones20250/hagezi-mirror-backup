# hagezi-mirror-backup

每周自动备份 [GitLab hagezi/mirror](https://gitlab.com/hagezi/mirror.git) 到本仓库（只增不删）。

[![Repository Backup](https://github.com/ones20250/hagezi-mirror-backup/actions/workflows/backup.yml/badge.svg)](https://github.com/ones20250/hagezi-mirror-backup/actions/workflows/backup.yml)

## 备份内容

| 位置 | 说明 |
|---|---|
| `refs/heads/upstream/hagezi-mirror/*` | 完整镜像分支（含全部 git 历史） |
| `refs/tags/upstream/hagezi-mirror/*` | 标签备份 |

浏览镜像：GitHub 仓库 → **Branches** → `upstream/hagezi-mirror/main`

## 特性

- **每周自动运行**（周日 03:00 UTC），也支持手动 `workflow_dispatch`
- **只同步新增**：先 `git ls-remote` 比对 SHA，无变化直接跳过，零带宽浪费
- **不删除**：push 永不 `--prune`。上游删掉的分支/tag、甚至上游整个仓库被删，备份都保留
- **防上游删库**：上游不可达时跳过该仓库，不会用空数据覆盖本地备份
- **多仓库扩展**：在 `config/repos.yml` 中新增条目即可

## 手动触发

仓库 → **Actions** → **Repository Backup** → **Run workflow**

## 新增备份源

编辑 `config/repos.yml`：

```yaml
repositories:
  - name: hagezi-mirror
    source: https://gitlab.com/hagezi/mirror.git
    releases: false
  # - name: another-repo
  #   source: https://github.com/user/repo.git
  #   releases: true
```

提交后推送即可，下一次运行时自动生效。

## 从备份恢复

```bash
git clone https://github.com/ones20250/hagezi-mirror-backup.git
git -C hagezi-mirror-backup fetch origin 'refs/heads/upstream/*:refs/heads/upstream/*'
git -C hagezi-mirror-backup switch upstream/hagezi-mirror/main
```
