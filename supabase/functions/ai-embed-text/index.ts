/// <reference types="https://esm.sh/@supabase/functions-js/edge-runtime.d.ts" />
// supabase/functions/ai-embed-text/index.ts
//
// Basit embedding servisi:
//  - input:  { "text": string }
//  - output: { "embedding": number[] }

type EmbedRequest = {
    text?: string;
};

type EmbedResponse = {
    embedding: number[];
};

const JSON_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
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

        const embedModel =
            Deno.env.get("GEMINI_EMBED_MODEL") ?? "text-embedding-004";

        const bodyText = await req.text();
        let body: EmbedRequest = {};
        try {
            body = bodyText ? JSON.parse(bodyText) : {};
        } catch {
            return new Response(
                JSON.stringify({ error: "Invalid JSON body" }),
                { status: 400, headers: JSON_HEADERS },
            );
        }

        const rawText = (body.text ?? "").toString();
        const text = rawText.trim();
        if (!text) {
            return new Response(
                JSON.stringify({ error: "text is required" }),
                { status: 400, headers: JSON_HEADERS },
            );
        }

        const embedding = await generateEmbedding({
            apiKey,
            embedModel,
            text,
        });

        const response: EmbedResponse = { embedding };

        return new Response(JSON.stringify(response), {
            status: 200,
            headers: JSON_HEADERS,
        });
    } catch (err) {
        console.error("ai-embed-text error:", err);
        return new Response(
            JSON.stringify({ error: "Internal error", details: String(err) }),
            { status: 500, headers: JSON_HEADERS },
        );
    }
});

// ---------------- Gemini embed helper ----------------

type EmbeddingArgs = {
    apiKey: string;
    embedModel: string;
    text: string;
};

async function generateEmbedding(args: EmbeddingArgs): Promise<number[]> {
    const { apiKey, embedModel, text } = args;

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
        throw new Error(
            `Gemini embedContent failed: ${resp.status} - ${errBody}`,
        );
    }

    const data = await resp.json();

    // Tek embedding:
    // { "embedding": { "values": [...] } }
    // veya
    // { "embeddings": [ { "values": [...] }, ... ] }
    const values: number[] | undefined =
        data?.embeddings?.[0]?.values ?? data?.embedding?.values;

    if (!values || !Array.isArray(values)) {
        console.error("Gemini embedding invalid:", data);
        throw new Error("Gemini embedding invalid");
    }

    return values.map((v) => Number(v));
}
