// Evaluate risk for a given username and IP address.
// Checks the in-memory risk profile store first; falls back to IP-based scoring for unknown users.
function evaluateRisk(EvaluateRequest evalReq) returns EvaluateAllowResponse|EvaluateDenyResponse {
    string username = evalReq.username;

    // Look up the user's pre-computed risk profile
    RiskProfile? riskProfile = riskProfileStore[username];
    if riskProfile is RiskProfile {
        boolean isAllowed = riskProfile.allow;
        if isAllowed {
            return {
                allow: true,
                score: riskProfile.score,
                riskLevel: riskProfile.riskLevel
            };
        }
        return {
            allow: false,
            score: riskProfile.score,
            riskLevel: riskProfile.riskLevel,
            reasons: riskProfile.reasons
        };
    }

    // Fallback: IP-based scoring for unknown users
    string ipAddress = evalReq.ipAddress;
    boolean isPoorIpReputation = ipAddress.startsWith("203.0.113.");
    boolean isImpossibleTravel = ipAddress.startsWith("198.51.100.");

    string[] riskReasons = [];
    if isPoorIpReputation {
        riskReasons.push("IP_REPUTATION_POOR");
    }
    if isImpossibleTravel {
        riskReasons.push("IMPOSSIBLE_TRAVEL");
    }

    int riskScore = (isPoorIpReputation ? 50 : 0) + (isImpossibleTravel ? 40 : 0);

    if riskScore >= 70 {
        return {allow: false, score: riskScore, riskLevel: "HIGH", reasons: riskReasons};
    } else if riskScore >= 40 {
        return {allow: false, score: riskScore, riskLevel: "MEDIUM", reasons: riskReasons};
    }
    return {allow: true, score: riskScore == 0 ? 12 : riskScore, riskLevel: "LOW"};
}
