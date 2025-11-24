/// <reference types="https://esm.sh/@supabase/functions-js/edge-runtime.d.ts" />

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type SearchRequest = {
  query?: string;  // opsiyonel
  tag?: string;    // opsiyonel
  limit?: number;
  user_id?: string;
};

type SearchResponse = {
  items: any[];
};

const JSON_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// ---------- Gemini embedding helper ----------
async function generateEmbedding(args: {
  apiKey: string;
  embedModel: string;
  text: string;
}): Promise<number[]> {
  const { apiKey, embedModel, text } = args;

  // ENV'de "text-embedding-004" veya "models/text-embedding-004"
  const modelName = embedModel.startsWith("models/")
    ? embedModel
    : `models/${embedModel}`;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/${modelName}:embedContent?key=${apiKey}`;

  const payload = {
    model: modelName,
    content: {
      parts: [{ text }],
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const errBody = await resp.text();
    console.error("Gemini embedContent error:", resp.status, errBody);
    throw new Error(
      `Gemini embedContent failed: ${resp.status} - ${errBody}`,
    );
  }

  const data = await resp.json();
  const values: number[] | undefined =
    data?.embeddings?.[0]?.values ?? data?.embedding?.values;

  if (!values || !Array.isArray(values)) {
    console.error("Gemini embedding invalid:", data);
    throw new Error("Gemini embedding invalid");
  }

  return values.map((v) => Number(v));
}

// ---------- Supabase client (service role ile) ----------
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

// ---------- HTTP handler ----------
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: JSON_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: JSON_HEADERS },
    );
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY is not set" }),
        { status: 500, headers: JSON_HEADERS },
      );
    }

    const embedModel =
      Deno.env.get("GEMINI_EMBED_MODEL") ?? "text-embedding-004";

    const bodyText = await req.text();
    let body: SearchRequest = {};

    try {
      body = bodyText ? (JSON.parse(bodyText) as SearchRequest) : {};
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // ---- Girişleri al + normalize et ----
    const rawQuery = (body.query ?? "").toString().trim();
    const rawTag = (body.tag ?? "").toString().trim();

    // Sorgu cümlesi: embedding için küçük harfe çeviriyoruz (model için fark etmez ama tutarlı)
    const queryForEmbed = rawQuery.toLowerCase();

    // Tag: hem burada hem SQL'de LOWER ile çalışacağız
    const tagNormalized = rawTag.toLowerCase();

    const limit = Number.isFinite(body.limit as number)
      ? (body.limit as number)
      : 20;
    const userId = (body.user_id ?? "").toString().trim();

    if (!userId) {
      return new Response(
        JSON.stringify({ error: "user_id is required" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // 🔹 Hem query hem tag boşsa: hata
    if (!rawQuery && !rawTag) {
      return new Response(
        JSON.stringify({ error: "Either query or tag is required" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // 🔹 Query varsa embedding üret, yoksa NULL gönder (sadece tag araması)
    let queryEmbedding: number[] | null = null;

    if (rawQuery) {
      queryEmbedding = await generateEmbedding({
        apiKey,
        embedModel,
        text: queryForEmbed,
      });
    }

    // 2) Postgres fonksiyonunu çağır
    const { data, error } = await supabase.rpc("ai_search_notes", {
      query_embedding: queryEmbedding,
      p_user_id: userId,
      match_count: limit,
      tag_filter: tagNormalized || null, // "" ise NULL gönder
    });

    if (error) {
      console.error("RPC ai_search_notes error:", error);
      return new Response(
        JSON.stringify({ error: "RPC error", details: error }),
        { status: 500, headers: JSON_HEADERS },
      );
    }

    const rows: any[] = Array.isArray(data) ? data : [];

    const response: SearchResponse = {
      items: rows,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: JSON_HEADERS,
    });
  } catch (err) {
    console.error("ai-search-notes error:", err);
    return new Response(
      JSON.stringify({ error: "Internal error", details: String(err) }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});
