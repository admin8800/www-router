## 构建

1. 编辑 `src/config.zig`，填写节点域名、探测路径与跳转路径。
2. 在项目根目录执行：

```powershell
zig build
```

产物目录：`zig-out/www/`（含 `index.html`、`app.js`、`selector.wasm`）。

本地预览：

```powershell
cd zig-out\www
python -m http.server 8080
```

浏览器打开 `http://127.0.0.1:8080`。

## 部署

将 `zig-out/www/` 整个目录上传到任意静态托管（Nginx / Caddy / OSS / Cloudflare Pages 等）。

Nginx 示例：

```nginx
server {
    listen 80;
    server_name gate.example.com;
    root /var/www/selector;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    types {
        application/wasm wasm;
    }
}
```

修改域名后重新执行 `zig build`，再覆盖上传 `zig-out/www/` 即可。
