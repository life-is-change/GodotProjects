const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const root = path.join(__dirname, "..", "build", "web");
const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".png": "image/png",
  ".pck": "application/octet-stream",
};

http.createServer((request, response) => {
  const route = request.url.split("?")[0];
  const name = route === "/" ? "index.html" : route.slice(1);
  if (!["GET", "HEAD"].includes(request.method) || !/^index\.[\w.-]+$/.test(name)) {
    response.writeHead(404).end();
    return;
  }
  const file = path.join(root, name);
  fs.stat(file, (error, stat) => {
    if (error || !stat.isFile()) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, {
      "Content-Type": types[path.extname(file)] || "application/octet-stream",
      "Content-Length": stat.size,
      "Cache-Control": "no-store",
    });
    if (request.method === "HEAD") response.end();
    else fs.createReadStream(file).pipe(response);
  });
}).listen(8067, "127.0.0.1", () => {
  console.log("http://127.0.0.1:8067/index.html");
});
