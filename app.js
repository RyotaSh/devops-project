const express = require("express");
const app = express();

app.get("/health", (_req, res) => res.status(200).send("OK"));

// v2: root endpoint that shows the version and the environment (from the ConfigMap)
app.get("/", (_req, res) =>
    res.send(`Hello from myapp v2 (env: ${process.env.APP_ENV || "local"})`)
);

if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => console.log(`Listening on ${PORT}`));
}

module.exports = app;