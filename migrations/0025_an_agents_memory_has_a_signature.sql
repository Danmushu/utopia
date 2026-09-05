-- Agent 写下的记忆必须能回答「谁借哪把钥匙说的」。来源跟在 episode chunk 上，
-- 而不是跟在共享的 Memory 文档或抽取 job 上：同一篇记忆日志会连续接收来自不同
-- Agent 的句子，文档级来源会在并发抽取时串号。
ALTER TABLE chunks
    ADD COLUMN recorded_by UUID REFERENCES users(id),
    ADD COLUMN recorded_via_token UUID REFERENCES personal_tokens(id) ON DELETE SET NULL;

-- 待确认行复制 chunk 的来源。这样列表不必回头猜当前 job 的调用者，也使 pending
-- 行在原 chunk 后续处理状态变化时仍有稳定归属。令牌撤销只打时间戳、不删行；若
-- 用户被物理级联删除，personal_tokens 随之删除，这里的令牌引用置空，不能反过来
-- 阻止既有 PAT 的删除语义。审核动作的自包含 snapshot 会保留当时的名称和前缀。
ALTER TABLE pending_facts
    ADD COLUMN proposed_via_token UUID
        REFERENCES personal_tokens(id) ON DELETE SET NULL;

CREATE INDEX chunks_recorded_via_token_idx ON chunks (recorded_via_token)
    WHERE recorded_via_token IS NOT NULL;
CREATE INDEX pending_facts_proposed_via_token_idx ON pending_facts (proposed_via_token)
    WHERE proposed_via_token IS NOT NULL;
