-- pgvector extension büyük ihtimalle Supabase projesinde zaten açık
-- Yine de idempotent olsun:
create extension if not exists vector;

-- ai_embedding kolonu için ivfflat index
create index if not exists idx_notes_ai_embedding
  on public.notes
  using ivfflat (ai_embedding vector_cosine_ops)
  with (lists = 100);
