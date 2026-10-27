# GitHub 仓库发布

工程已整理为本地 Git 仓库。请先在 GitHub 网页创建空仓库，然后运行：

```sh
git remote add origin https://github.com/你的用户名/仓库名.git
git push -u origin main
```

若安装并登录 GitHub CLI，也可以创建线上仓库并推送：

```sh
gh auth login
gh repo create FairyGreybox --private --source=. --remote=origin --push
```

公开或私有由项目所有者在创建时选择。推送前检查不要包含本地用户存档、密钥或真实身份资料。`.gitignore` 已排除Godot缓存、用户存档与本地导出包。
