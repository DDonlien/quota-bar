// QuotaBarTests —— 测试基建
//
// 当前没有任何具体测试用例。每个具体测试应该是所属功能任务的子任务（按 AGENTS.md 第 3 节规则），
// 不在 phase 顶层登记。本目录只用于 `swift test` 不报错 + `make test` 能跑通。
//
// 加测试时直接在新文件里 import QuotaBar，写 @Test 或 XCTestCase 即可。

import Testing
@testable import QuotaBar

@Test
func placeholder() {
    // 测试基建占位，验证 swift test 能运行。
    // 真正的测试是各功能任务的 <parent>-test 子任务。
    #expect(1 + 1 == 2)
}
