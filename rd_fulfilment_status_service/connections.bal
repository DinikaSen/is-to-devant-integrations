// In-memory seed data for fulfilment lines, keyed by "<orderId>-<lineNo>"
final map<FulfilmentLine> & readonly fulfilmentLineStore = {
    "1001-1": {key: "1001-1", orderId: "1001", lineNo: "1", status: "SHIPPED", carrier: "DHL", eta: "2026-10-12", lastUpdated: "2026-10-07T00:00:00Z"},
    "1002-1": {key: "1002-1", orderId: "1002", lineNo: "1", status: "PICKING", eta: "2026-10-14", lastUpdated: "2026-10-07T00:00:00Z"},
    "5001-1": {key: "5001-1", orderId: "5001", lineNo: "1", status: "IN_TRANSIT", carrier: "UPS", eta: "2026-10-11", lastUpdated: "2026-10-07T00:00:00Z"},
    "6001-1": {key: "6001-1", orderId: "6001", lineNo: "1", status: "DELIVERED", carrier: "DHL", eta: "2026-10-08", lastUpdated: "2026-10-07T00:00:00Z"}
};

// Mutable admin state: current mode and slow-mode delay
isolated AdminState adminState = {mode: "NORMAL", delayMs: defaultSlowDelayMs};

// Mutable request statistics: total calls and counts by outcome
isolated StatsState statsState = {totalCalls: 0, byOutcome: {}};
