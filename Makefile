.PHONY: help build run test app site web clean deploy link all

# Quota Bar —— 统一开发入口
# 跟 AGENTS.md / README 的命令一致；CI workflow 也走相同的脚本。

help:
	@echo "Quota Bar dev entrypoints:"
	@echo "  make build  - swift build (debug)"
	@echo "  make run    - swift run (启动菜单栏 app)"
	@echo "  make test   - swift test (单元测试)"
	@echo "  make app    - 打包 .app (build/<timestamp>/Quota Bar.app)"
	@echo "  make site   - 构建 site 子项目 (Astro 站点)"
	@echo "  make link   - 把 site/ 链接到 Vercel 项目（首次部署前跑一次）"
	@echo "  make deploy - 用 Vercel CLI 部署 site 子项目到生产环境"
	@echo "  make clean  - 清理 macos/.build 和 site/node_modules / site/dist"
	@echo "  make all    - build + app + site"

build:
	cd macos && swift build

run:
	cd macos && swift run

test:
	cd macos && swift test

app:
	cd macos && ./scripts/build-app.sh

site:
	cd site && npm ci && npm run build

# 兼容旧命令；新文档统一使用 make site。
web: site

# 把本地 site/ 链接到 Vercel 上的 quota-bar-site 项目。
# 首次跑会要求登录 + 选项目/team；之后 vercel link 会创建 .vercel/project.json
link:
	cd site && vercel link

# 用 Vercel CLI 部署 site/ 到生产环境。
# 前置：make link 一次 + 在 Vercel dashboard 添加了 quotabar.ddonlien.com 域名
deploy:
	cd site && vercel --prod

# 只读访问 Vercel API 验证 auth / 列项目（不部署）。
# 失败通常是 token 过期 / OIDC discovery 不可达。
vercel-check:
	vercel whoami 2>&1 || echo "❌ vercel whoami 失败 — 需要重新 vercel login 或换 VERCEL_TOKEN"

clean:
	rm -rf macos/.build macos/.swiftpm
	rm -rf site/node_modules site/dist site/.astro

all: build app site
