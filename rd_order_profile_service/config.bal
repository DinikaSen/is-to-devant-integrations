// HTTP listener port
configurable int servicePort = 8080;

// Default delay (ms) applied when admin mode is SLOW
configurable int defaultSlowDelayMs = 3000;

// Optional HTTP basic auth on the data endpoint
configurable boolean basicAuthEnabled = false;
configurable string basicAuthUsername = "admin";
configurable string basicAuthPassword = "";
