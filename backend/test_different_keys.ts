async function testKeys() {
  const keys = [
    // 1. Exactly as copied from user text
    "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",
    // 2. Casing from screenshot: lURJGemt1I4SyaUM...
    "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",
    // 3. Another variation
    "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"
  ];
  
  const url = "https://integrate.api.nvidia.com/v1/chat/completions";
  const modelName = "meta/llama-3.1-8b-instruct";
  
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    console.log(`\n--- Testing Key Option ${i+1}: ${key.substring(0, 25)}... ---`);
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${key}`,
        },
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: "user", content: "hi" }],
          max_tokens: 10,
        }),
      });
      
      console.log("Status:", response.status);
      const text = await response.text();
      console.log("Body:", text.substring(0, 100));
    } catch (e) {
      console.error("Failed:", e);
    }
  }
}

testKeys();
