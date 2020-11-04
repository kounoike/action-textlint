const rcFile = require("rc-config-loader")

result = rcFile.rcFile("textlint", {
    cwd: process.env.GITHUB_WORKSPACE
});

if (result.config.plugins) {
    for (const [key, value] of Object.entries(result.config.plugins)) {
        if (value != false) {
            if (key.startsWith("@")) {
                const scope = key.slice(0, key.indexOf("/"));
                const name = key.slice(key.indexOf('/') + 1);
                console.log(`${scope}/textlint-plugin-${name}`);
            } else {
                console.log(`textlint-plugin-${key}`);
            }
        }
    }
}

if (result.config.rules) {
    for (const [key, value] of Object.entries(result.config.rules)) {
        if (value != false) {
            console.log(`textlint-rule-${key}`)
        }
    }
}
