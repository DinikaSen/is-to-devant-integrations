// In-memory risk profile store seeded with 6 users
map<RiskProfile> riskProfileStore = {
    "alice@demo.io": {
        username: "alice@demo.io",
        score: 8,
        riskLevel: "LOW",
        allow: true,
        reasons: []
    },
    "bob@demo.io": {
        username: "bob@demo.io",
        score: 15,
        riskLevel: "LOW",
        allow: true,
        reasons: []
    },
    "carol@demo.io": {
        username: "carol@demo.io",
        score: 22,
        riskLevel: "LOW",
        allow: true,
        reasons: []
    },
    "dave@demo.io": {
        username: "dave@demo.io",
        score: 87,
        riskLevel: "HIGH",
        allow: false,
        reasons: ["IP_REPUTATION_POOR", "IMPOSSIBLE_TRAVEL"]
    },
    "eve@demo.io": {
        username: "eve@demo.io",
        score: 91,
        riskLevel: "HIGH",
        allow: false,
        reasons: ["BRUTE_FORCE_DETECTED", "ACCOUNT_COMPROMISED"]
    },
    "frank@demo.io": {
        username: "frank@demo.io",
        score: 55,
        riskLevel: "MEDIUM",
        allow: false,
        reasons: ["GEO_ANOMALY"]
    }
};
