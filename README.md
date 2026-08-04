## 构建

1. 编辑 `src/config.zig`，填写节点域名、探测路径与跳转路径。
2. 在项目根目录执行：

```powershell
zig build
```

产物目录：`zig-out/www/`（含 `index.html`、`selector.wasm`）。

本地预览：

```powershell
cd zig-out\www
python -m http.server
```

浏览器打开 `http://127.0.0.1:8000`。

## 部署

将 `zig-out/www/` 整个目录上传到任意静态托管（Nginx / Caddy / Cloudflare Pages 等）。

caddy 示例：

```nginx
example.com {
    root * /var/www
    encode zstd gzip
    file_server
}
```

修改域名后重新执行 `zig build`，再覆盖上传 `zig-out/www/` 即可。
