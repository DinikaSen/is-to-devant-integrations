// Internal risk profile stored in the in-memory database
type RiskProfile record {|
    string username;
    int score;
    string riskLevel;
    boolean allow;
    string[] reasons;
|};

// Request/Response types

type EvaluateRequest record {|
    string username;
    string ipAddress;
|};

type EvaluateAllowResponse record {|
    boolean allow;
    int score;
    string riskLevel;
|};

type EvaluateDenyResponse record {|
    boolean allow;
    int score;
    string riskLevel;
    string[] reasons;
|};
