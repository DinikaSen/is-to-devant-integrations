import ballerina/time;

// Lookup a user by username
function lookupUser(string username) returns LookupFoundResponse|LookupNotFoundResponse {
    foreach UserRecord userRecord in userStore {
        string storedUsername = userRecord.username;
        if storedUsername == username {
            return {
                exists: true,
                externalId: userRecord.externalId,
                username: userRecord.username,
                status: userRecord.status,
                createdAt: userRecord.createdAt
            };
        }
    }
    return {exists: false, username: username};
}

// Generate a new external ID based on current store size
function generateExternalId() returns string {
    int nextId = userStore.length() + 10001;
    return string `EXT-${nextId}`;
}

// Create a new user and add to the in-memory store
function createUser(CreateUserRequest createReq) returns CreateUserResponse {
    string newExternalId = generateExternalId();
    time:Utc currentUtc = time:utcNow();
    string createdAtStr = time:utcToString(currentUtc);

    UserRecord newUser = {
        externalId: newExternalId,
        username: createReq.username,
        email: createReq.email,
        wso2UserId: createReq.wso2UserId,
        firstName: createReq.firstName,
        lastName: createReq.lastName,
        'source: createReq.'source,
        status: "ACTIVE",
        createdAt: createdAtStr
    };
    userStore.push(newUser);

    return {
        externalId: newExternalId,
        username: createReq.username,
        status: "ACTIVE"
    };
}
