const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

exports.analyzePatient = onCall(
  {
    region: "us-central1",
    secrets: [OPENAI_API_KEY],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    // Require Firebase Authentication.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to use Medicare AI."
      );
    }

    const data = request.data || {};

    const latestVitals = data.latestVitals || {};
    const history = Array.isArray(data.history) ? data.history : [];
    const dailyCheckIns = Array.isArray(data.dailyCheckIns)
      ? data.dailyCheckIns
      : [];

    const prompt = `
You are the AI analysis component of MEDICARE, an academic biomedical
patient-monitoring prototype.

IMPORTANT:
- This is NOT a diagnostic system.
- Do not diagnose disease.
- Do not claim certainty.
- Use conservative language.
- If measurements or symptoms may be concerning, advise the patient
  to contact a qualified healthcare professional.
- Base your answer only on the supplied data.

CURRENT VITALS:
Heart rate: ${latestVitals.heartRate ?? "not available"} bpm
SpO2: ${latestVitals.spo2 ?? "not available"} %
Body temperature: ${latestVitals.bodyTemperature ?? "not available"} °C
Room temperature: ${latestVitals.roomTemperature ?? "not available"} °C
Humidity: ${latestVitals.humidity ?? "not available"} %
Battery: ${latestVitals.batteryPercent ?? "not available"} %
Alert: ${latestVitals.alert ?? false}
ECG lead off: ${latestVitals.ecgLeadOff ?? false}

RECENT MONITORING HISTORY:
${JSON.stringify(history)}

RECENT DAILY CHECK-INS:
${JSON.stringify(dailyCheckIns)}

Analyze the measurements and trends.

Respond using exactly these sections:

RISK LEVEL:
Low, Moderate, or High

TREND:
Stable, Improving, Worsening, or Insufficient data

CURRENT MONITORING SUMMARY:

PATTERN REVIEW:

POSSIBLE CONCERNS:

RECOMMENDATION:

IMPORTANT:
State clearly that Medicare provides monitoring and decision support
and does not replace professional medical diagnosis or treatment.
`;

    try {
      const response = await fetch(
        "https://api.openai.com/v1/responses",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
          },
          body: JSON.stringify({
            model: "gpt-5.6-luna",
            input: prompt,
            reasoning: {
              effort: "low",
            },
            max_output_tokens: 1200,
          }),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        console.error("OpenAI API error:", result);

        throw new HttpsError(
          "internal",
          `OpenAI request failed with status ${response.status}.`
        );
      }

      let text = "";

      if (
        typeof result.output_text === "string" &&
        result.output_text.trim().length > 0
      ) {
        text = result.output_text.trim();
      }

      // Fallback parser in case output_text is unavailable.
      if (!text && Array.isArray(result.output)) {
        const parts = [];

        for (const item of result.output) {
          if (!item || !Array.isArray(item.content)) {
            continue;
          }

          for (const content of item.content) {
            if (
              content &&
              typeof content.text === "string" &&
              content.text.trim().length > 0
            ) {
              parts.push(content.text.trim());
            }
          }
        }

        text = parts.join("\n\n").trim();
      }

      if (!text) {
        console.error("Unexpected OpenAI response:", result);

        throw new HttpsError(
          "internal",
          "OpenAI returned no readable analysis."
        );
      }

      return {
        analysis: text,
      };
    } catch (error) {
      console.error("Medicare AI error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Medicare AI analysis could not be completed."
      );
    }
  }
);