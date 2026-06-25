.PHONY: help build run test app web clean all

# Quota Bar —— 统一开发入口
# 跟 AGENTS.md / README 的命令一致；CI workflow 也走相同的脚本。

help:
	@echo "Quota Bar dev entrypoints:"
	@echo "  make build  - swift build (debug)"
	@echo "  make run    - swift run (启动菜单栏 app)"
	@echo "  make test   - swift test (单元测试)"
	@echo "  make app    - 打包 .app (build/<timestamp>/QuotaBar.app)"
	@echo "  make web    - 构建 web 子项目 (Astro 站点)"
	@echo "  make clean  - 清理 quota-bar/.build 和 web/node_modules / web/dist"
	@echo "  make all    - build + app + web"

build:
	cd quota-bar && swift build

run:
	cd quota-bar && swift run

test:
	cd quota-bar && swift test

app:
	cd quota-bar && ./scripts/build-app.sh

web:
	cd web && npm ci && npm run build

clean:
	rm -rf quota-bar/.build quota-bar/.swiftpm
	rm -rf web/node_modules web/dist web/.astro

all: build app web
