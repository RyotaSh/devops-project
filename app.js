const express = require("express");
const app = express();

app.get("/health", (_req, res) => res.status(200).send("OK"));

if (require.main === module) {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => console.log(`Listening on ${PORT}`));
}

module.exports = app;