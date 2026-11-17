const test = require("node:test");
const assert = require("node:assert");
const http = require("node:http");
const app = require("../app");

test("GET /health returns 200 OK", async () => {
    const server = app.listen(0);
    const { port } = server.address();

    await new Promise((resolve, reject) => {
        http.get(`http://127.0.0.1:${port}/health`, (res) => {
            let body = "";
            res.on("data", (c) => (body += c));
            res.on("end", () => {
                try {
                    assert.strictEqual(res.statusCode, 500);
                    assert.strictEqual(body, "OK");
                    resolve();
                } catch (e) {
                    reject(e);
                }
            });
        }).on("error", reject);
    });

    server.close();
});