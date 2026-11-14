static bool Disabled() {
    static const bool disabled = [] {
        char path[MAX_PATH] = {};
        GetModuleFileNameA(nullptr, path, MAX_PATH);
        char* slash = strrchr(path, 92);
        if (!slash) {
            return false;
        }
        strcpy(slash + 1, "EsteriaOff.txt");
        return GetFileAttributesA(path) != INVALID_FILE_ATTRIBUTES;
    }();
    return disabled;
}

