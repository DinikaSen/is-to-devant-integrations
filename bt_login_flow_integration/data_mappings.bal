
function transform(UserstoreLookupFoundResponse lookupResult, RiskEvaluateResponse riskResult) returns LoginDecisionResponse => {
    reason: "",
    decision: lookupResult.exists,
    userStore: {exists: false}
};
