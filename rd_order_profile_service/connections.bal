// In-memory seed data for order lines, keyed by "<orderId>-<lineNo>"
final map<OrderLine> & readonly orderLineStore = {
    "1001-1": {key: "1001-1", orderId: "1001", lineNo: "1", customer: "ACME", sku: "A-100", qty: 2, amount: 40.00, costCentre: "CC-4410"},
    "1002-1": {key: "1002-1", orderId: "1002", lineNo: "1", customer: "ACME", sku: "B-200", qty: 1, amount: 12.50, costCentre: "CC-4410"},
    "5001-1": {key: "5001-1", orderId: "5001", lineNo: "1", customer: "GLOBEX", sku: "C-300", qty: 5, amount: 99.00, costCentre: "CC-5520"},
    "6001-1": {key: "6001-1", orderId: "6001", lineNo: "1", customer: "INITECH", sku: "D-400", qty: 3, amount: 21.00, costCentre: "CC-4410"}
};

// Mutable admin state: current mode and slow-mode delay
isolated AdminModeResponse adminState = {mode: "NORMAL", delayMs: defaultSlowDelayMs};

// Mutable request statistics: total calls and counts by outcome, held as a single protected value
isolated StatsState statsState = {totalCalls: 0, byOutcome: {}};
