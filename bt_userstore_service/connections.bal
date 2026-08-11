import ballerina/io;
import ballerina/log;

// In-memory user store loaded from JSON file at startup
UserRecord[] userStore = loadUsersFromFile();

function loadUsersFromFile() returns UserRecord[] {
    json|io:Error fileContent = io:fileReadJson("./resources/users.json");
    if fileContent is io:Error {
        log:printError("Failed to load users.json, starting with empty store", 'error = fileContent);
        return [];
    }
    UserRecord[]|error users = fileContent.cloneWithType();
    if users is error {
        log:printError("Failed to parse users.json into UserRecord array", 'error = users);
        return [];
    }
    return users;
}
