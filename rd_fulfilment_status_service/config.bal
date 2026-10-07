// HTTP listener port
configurable int servicePort = 8080;

// Delay (ms) applied to requests whose orderId starts with "5" (simulated slow backend)
configurable int slowOrderDelayMs = 3000;

// Default delay (ms) applied when admin mode is SLOW
configurable int defaultSlowDelayMs = 3000;
