/// <reference types="https://esm.sh/@supabase/functions-js/edge-runtime.d.ts" />
// supabase/functions/ai-process-note/index.ts

// Bu function:
// - title + content + mode alır
// - Gemini ile summary + tags + ai_meta üretir
// - text-embedding-004 ile embedding üretir
// - Flutter'ın AIProcessedNote modeline uygun JSON döner:
//
// {
//   "summary": string,
//   "tags": string[],
//   "ai_meta": {
//     "keywords": string[],
//     "sentiment": "positive" | "negative" | "neutral",
//     "importance": number,
//     "mode": "suggest_fix" | "auto_expand" | "title_only",
//     "suggested_content": string
//   },
//   "embedding": number[]
// }

type AiMeta = {
  keywords: string[];
  sentiment: string;
  importance: number;
  mode: string;
  suggested_content: string;
};

type AiResponse = {
  summary: string;
  tags: string[];
  ai_meta: AiMeta;
  embedding: number[];
};

const JSON_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*", // Gerekirse domain kısıtlayabilirsin
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

Deno.serve(async (req) => {
  // CORS preflight
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

    const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
    const embedModel =
      Deno.env.get("GEMINI_EMBED_MODEL") ?? "text-embedding-004";

    const bodyText = await req.text();
    let body: any = {};
    try {
      body = bodyText ? JSON.parse(bodyText) : {};
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    const rawTitle = (body.title ?? "").toString();
    const rawContent = (body.content ?? "").toString();
    const mode = (body.mode ?? "auto").toString();

    if (!rawTitle.trim() && !rawContent.trim()) {
      return new Response(
        JSON.stringify({ error: "title or content is required" }),
        { status: 400, headers: JSON_HEADERS },
      );
    }

    // analize gönderilecek metin
    const combinedText = [rawTitle, rawContent]
      .filter((s) => s.trim().length > 0)
      .join("\n\n")
      .trim();

    // 1) Gemini'den summary + tags + ai_meta al
    const analysis = await generateAnalysis({
      apiKey,
      model,
      text: combinedText,
      mode,
    });

    // 2) text-embedding-004 ile embedding al
    const embedding = await generateEmbedding({
      apiKey,
      embedModel,
      text: combinedText,
    });

    const response: AiResponse = {
      summary: analysis.summary,
      tags: analysis.tags,
      ai_meta: analysis.ai_meta,
      embedding,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: JSON_HEADERS,
    });
  } catch (err) {
    console.error("ai-process-note error:", err);
    return new Response(
      JSON.stringify({ error: "Internal error", details: String(err) }),
      { status: 500, headers: JSON_HEADERS },
    );
  }
});

// ---------------- Gemini yardımcı fonksiyonları ----------------

type AnalysisArgs = {
  apiKey: string;
  model: string;
  text: string;
  mode: string; // 'auto' | 'enhance' | 'list' | 'from_title'
};

async function generateAnalysis(args: AnalysisArgs): Promise<{
  summary: string;
  tags: string[];
  ai_meta: AiMeta;
}> {
  const { apiKey, model, text, mode } = args;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const prompt = `
Sen akıllı bir not editörüsün.

Aşağıdaki NOT için:
- Türkçe kısa bir özet üret (1-2 cümle).
- 3-7 arası Türkçe etiket üret (tags).
- Aşağıdaki alanları doldur:
  - keywords: 3-10 arası anahtar kelime
  - sentiment: "positive" | "negative" | "neutral"
  - importance: 1-5 arası tamsayı
  - mode:
      "suggest_fix"  : Kullanıcının yazım / ifade hatalarını düzelt,
      "auto_expand"  : İçeriği kullanıcı stilini bozmadan genişlet,
      "title_only"   : İçerik yoksa başlıktan mantıklı içerik üret.

Ayrıca dışarıya "suggested_content" alanında, kullanıcının notuna
doğrudan kaydedilebilecek TAM VE TEMİZ metni döndür.

Şu anki UI modu: "${mode}"

ÇIKTIYI SADECE AŞAĞIDAKİ JSON FORMATINDA DÖN.
JSON dışında hiçbir açıklama, kod bloğu, markdown, metin ekleme:
{
  "summary": "kısa özet",
  "tags": ["etiket1", "etiket2"],
  "ai_meta": {
    "keywords": ["kelime1", "kelime2"],
    "sentiment": "positive|negative|neutral",
    "importance": 1,
    "mode": "suggest_fix|auto_expand|title_only",
    "suggested_content": "tam ve temiz içerik"
  }
}

NOT:
${text}
`.trim();

  const payload = {
    contents: [
      {
        role: "user",
        parts: [{ text: prompt }],
      },
    ],
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const errBody = await resp.text();
    console.error("Gemini generateContent error:", resp.status, errBody);
    throw new Error(`Gemini generateContent failed: ${resp.status}`);
  }

  const data = await resp.json();

  const textPart: string | undefined =
    data?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!textPart) {
    console.error("Gemini response has no text part:", data);
    throw new Error("Gemini response invalid (no text)");
  }

  // -------- JSON parse (dayanıklı) --------
  let parsed: any;
  let cleaned = textPart.trim();

  try {
    // ```json ... ``` veya ``` ... ``` code fence'lerini temizle
    if (cleaned.startsWith("```")) {
      cleaned = cleaned.replace(/^```[a-zA-Z]*\n?/, "");
      if (cleaned.endsWith("```")) {
        cleaned = cleaned.slice(0, -3);
      }
      cleaned = cleaned.trim();
    }

    // İlk { ile son } arasını al
    const firstBrace = cleaned.indexOf("{");
    const lastBrace = cleaned.lastIndexOf("}");
    if (
      firstBrace !== -1 &&
      lastBrace !== -1 &&
      lastBrace > firstBrace
    ) {
      cleaned = cleaned.slice(firstBrace, lastBrace + 1);
    }

    parsed = JSON.parse(cleaned);
  } catch (e) {
    console.error("Gemini JSON parse error:", e, cleaned);

    // Parse edilemezse fallback: notun kendisinden özet/öneri üret
    const trimmed = text.trim();
    const summaryFallback =
      trimmed.length > 200 ? trimmed.slice(0, 200) + "..." : trimmed;

    const fallbackMeta: AiMeta = {
      keywords: [],
      sentiment: "neutral",
      importance: 1,
      mode: "suggest_fix",
      // En azından kullanıcının yazdığı metni geri verelim
      suggested_content: trimmed,
    };

    return {
      summary: summaryFallback,
      tags: [],
      ai_meta: fallbackMeta,
    };
  }

  const summary = (parsed.summary ?? "").toString();

  const tags: string[] = Array.isArray(parsed.tags)
    ? parsed.tags
      .map((t: unknown) => (t ?? "").toString().trim())
      .filter((t: string) => t.length > 0)
    : [];

  const aiMetaRaw = parsed.ai_meta ?? {};
  const keywords: string[] = Array.isArray(aiMetaRaw.keywords)
    ? aiMetaRaw.keywords
      .map((k: unknown) => (k ?? "").toString().trim())
      .filter((k: string) => k.length > 0)
    : [];

  let sentiment = (aiMetaRaw.sentiment ?? "neutral").toString().toLowerCase();
  if (!["positive", "negative", "neutral"].includes(sentiment)) {
    sentiment = "neutral";
  }

  let importance = Number(aiMetaRaw.importance ?? 1);
  if (!Number.isFinite(importance)) importance = 1;
  importance = Math.max(1, Math.min(5, Math.round(importance)));

  let metaMode = (aiMetaRaw.mode ?? "suggest_fix").toString();
  if (!["suggest_fix", "auto_expand", "title_only"].includes(metaMode)) {
    metaMode = "suggest_fix";
  }

  const suggestedContent = (aiMetaRaw.suggested_content ?? "").toString();

  const ai_meta: AiMeta = {
    keywords,
    sentiment,
    importance,
    mode: metaMode,
    suggested_content: suggestedContent,
  };

  return {
    summary,
    tags,
    ai_meta,
  };
}

type EmbeddingArgs = {
  apiKey: string;
  embedModel: string;
  text: string;
};

async function generateEmbedding(args: EmbeddingArgs): Promise<number[]> {
  const { apiKey, embedModel, text } = args;

  // REST endpoint
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${embedModel}:embedContent?key=${apiKey}`;

  // text-embedding-004 için doğru payload:
  // {
  //   "model": "models/text-embedding-004",
  //   "content": { "parts": [ { "text": "..." } ] }
  // }
  const modelName = embedModel.startsWith("models/")
    ? embedModel
    : `models/${embedModel}`;

  const payload = {
    model: modelName,
    content: {
      parts: [{ text }],
    },
  };

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const errBody = await resp.text();
    console.error("Gemini embedContent error:", resp.status, errBody);
    throw new Error(`Gemini embedContent failed: ${resp.status} - ${errBody}`);
  }

  const data = await resp.json();

  // Tek embedding: { "embedding": { "values": [...] } }
  // Çoklu embedding: { "embeddings": [ { "values": [...] }, ... ] }
  const values: number[] | undefined =
    data?.embeddings?.[0]?.values ?? data?.embedding?.values;

  if (!values || !Array.isArray(values)) {
    console.error("Gemini embedding invalid:", data);
    throw new Error("Gemini embedding invalid");
  }

  return values.map((v) => Number(v));
}
