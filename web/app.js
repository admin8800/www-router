(() => {
  const $ = (id) => document.getElementById(id);
  const err = (t) => {
    $("sp").style.display = "none";
    $("err").style.display = "block";
    $("err").textContent = t;
    $("msg").textContent = "请刷新重试或检查网络";
  };

  const u8 = (m, p, n) => new TextDecoder().decode(new Uint8Array(m.buffer, p, n));

  async function ping(url, ms) {
    const c = new AbortController();
    const t = setTimeout(() => c.abort(), ms);
    const t0 = performance.now();
    try {
      await fetch(url + (url.includes("?") ? "&" : "?") + "_=" + Date.now(), {
        mode: "no-cors",
        cache: "no-store",
        signal: c.signal,
      });
      return Math.round(performance.now() - t0);
    } catch {
      return -1;
    } finally {
      clearTimeout(t);
    }
  }

  (async () => {
    let wasm;
    try {
      const r = await fetch("selector.wasm", { cache: "no-store" });
      if (!r.ok) throw new Error("wasm");
      const { instance } = await WebAssembly.instantiate(await r.arrayBuffer());
      wasm = instance.exports;
    } catch {
      err("资源加载失败");
      return;
    }

    const mem = wasm.memory;
    const n = wasm.node_count() >>> 0;
    const to = wasm.timeout_ms() | 0;
    const out = wasm.out_ptr() >>> 0;
    const lp = wasm.latency_ptr() >>> 0;
    const lview = new Int32Array(mem.buffer, lp, n);

    $("msg").textContent = "并行测速中…";

    const jobs = [];
    for (let i = 0; i < n; i++) {
      const len = wasm.probe_url(i);
      if (len < 0) {
        lview[i] = -1;
        continue;
      }
      const url = u8(mem, out, len);
      jobs.push(
        ping(url, to).then((ms) => {
          lview[i] = ms;
        })
      );
    }
    await Promise.all(jobs);

    const blen = wasm.pick_best(lp, n);
    if (blen < 0) {
      err("所有线路均不可用");
      return;
    }

    const dest = u8(mem, out, blen);
    $("msg").textContent = "即将跳转…";
    location.replace(dest);
  })();
})();
