package dz.sayida.rozqi;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.Toast;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity {
    private static final String HOST = "dz.sayida.rozqi";
    private static final String BASE = "https://dz.sayida.rozqi/";
    private WebView web;
    private FrameLayout root;
    private View full;
    private WebChromeClient.CustomViewCallback fullCallback;
    private int oldUi;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(0xff2c180e);
        getWindow().setNavigationBarColor(0xff2c180e);
        root = new FrameLayout(this);
        web = new WebView(this);
        web.setBackgroundColor(0xfff6efdf);
        root.addView(web, new FrameLayout.LayoutParams(-1, -1));
        setContentView(root);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        s.setJavaScriptCanOpenWindowsAutomatically(false);
        s.setSupportMultipleWindows(false);
        s.setMediaPlaybackRequiresUserGesture(true);
        configure();
        loadInterface();
    }

    private WebResourceResponse asset(Uri uri) {
        if (!"https".equalsIgnoreCase(uri.getScheme()) || !HOST.equalsIgnoreCase(uri.getHost())) return null;
        String p = uri.getPath(), f = null, mime = null, enc = null;
        if ("/banner.jpg".equals(p)) { f = "banner.jpg"; mime = "image/jpeg"; }
        else if ("/logo.png".equals(p)) { f = "logo.png"; mime = "image/png"; }
        else if ("/upgrade.css".equals(p)) { f = "upgrade.css"; mime = "text/css"; enc = "UTF-8"; }
        else if ("/upgrade.js".equals(p)) { f = "upgrade.js"; mime = "text/javascript"; enc = "UTF-8"; }
        try { if (f != null) return new WebResourceResponse(mime, enc, getAssets().open(f)); }
        catch (Exception ignored) { }
        return new WebResourceResponse("text/plain", "UTF-8", new ByteArrayInputStream(new byte[0]));
    }

    private void configure() {
        web.setWebViewClient(new WebViewClient() {
            @Override public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) { return asset(r.getUrl()); }
            @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                if (!r.isForMainFrame()) return !"https".equalsIgnoreCase(r.getUrl().getScheme());
                external(r.getUrl()); return true;
            }
            @Override public boolean shouldOverrideUrlLoading(WebView v, String url) {
                Uri u = Uri.parse(url); String h = u.getHost(), p = u.getPath();
                if ("https".equalsIgnoreCase(u.getScheme()) && "www.youtube.com".equalsIgnoreCase(h) && p != null && p.startsWith("/embed/")) return false;
                external(u); return true;
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override public boolean onJsAlert(WebView v, String u, String m, final JsResult r) {
                new AlertDialog.Builder(MainActivity.this).setTitle("السيدة رزقي").setMessage(m)
                    .setPositiveButton("حسنًا", (d,w) -> r.confirm()).setOnCancelListener(d -> r.cancel()).show(); return true;
            }
            @Override public boolean onJsConfirm(WebView v, String u, String m, final JsResult r) {
                new AlertDialog.Builder(MainActivity.this).setTitle("تأكيد").setMessage(m)
                    .setPositiveButton("نعم", (d,w) -> r.confirm()).setNegativeButton("إلغاء", (d,w) -> r.cancel())
                    .setOnCancelListener(d -> r.cancel()).show(); return true;
            }
            @Override public void onShowCustomView(View v, WebChromeClient.CustomViewCallback cb) {
                if (full != null) { cb.onCustomViewHidden(); return; }
                oldUi = getWindow().getDecorView().getSystemUiVisibility(); full = v; fullCallback = cb;
                v.setBackgroundColor(Color.BLACK); root.addView(v, new FrameLayout.LayoutParams(-1,-1)); web.setVisibility(View.GONE);
                getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
            }
            @Override public void onHideCustomView() { exitFull(); }
        });
    }

    private void external(Uri u) {
        if (u == null) return;
        if (!"https".equalsIgnoreCase(u.getScheme())) { Toast.makeText(this, "يسمح بروابط HTTPS فقط", Toast.LENGTH_SHORT).show(); return; }
        String h = u.getHost(); if (h == null || h.isEmpty() || HOST.equalsIgnoreCase(h)) return;
        try { Intent i = new Intent(Intent.ACTION_VIEW,u); i.addCategory(Intent.CATEGORY_BROWSABLE); startActivity(i); }
        catch (ActivityNotFoundException e) { Toast.makeText(this, "لا يوجد تطبيق مناسب لفتح الرابط", Toast.LENGTH_LONG).show(); }
    }

    private void exitFull() {
        if (full == null) return; root.removeView(full); full = null;
        if (web != null) web.setVisibility(View.VISIBLE);
        getWindow().getDecorView().setSystemUiVisibility(oldUi);
        WebChromeClient.CustomViewCallback cb = fullCallback; fullCallback = null; if (cb != null) cb.onCustomViewHidden();
    }

    private void loadInterface() {
        StringBuilder html = new StringBuilder();
        try (BufferedReader r = new BufferedReader(new InputStreamReader(getAssets().open("index.html"),StandardCharsets.UTF_8))) {
            String line; while ((line = r.readLine()) != null) { html.append(line); html.append((char)10); }
            String page = html.toString().replace("</head>", "<meta name='referrer' content='strict-origin-when-cross-origin'><link rel='stylesheet' href='upgrade.css'></head>")
                .replace("</body>", "<script src='upgrade.js'></script></body>");
            web.loadDataWithBaseURL(BASE,page,"text/html","UTF-8",BASE);
        } catch (Exception e) {
            new AlertDialog.Builder(this).setTitle("تعذر فتح الواجهة").setMessage("تأكدي من وجود app/src/main/assets/index.html")
                .setPositiveButton("إغلاق",(d,w) -> finish()).setCancelable(false).show();
        }
    }

    @Override public void onBackPressed() {
        if (full != null) { exitFull(); return; } if (web == null) { super.onBackPressed(); return; }
        web.evaluateJavascript("(function(){if(typeof window.appBack==='function'){window.appBack();}})();",null);
    }
    @Override protected void onPause() { if (web != null) web.onPause(); super.onPause(); }
    @Override protected void onResume() { super.onResume(); if (web != null) web.onResume(); }
    @Override protected void onDestroy() { exitFull(); if (web != null) { web.stopLoading(); root.removeView(web); web.destroy(); web = null; } super.onDestroy(); }
}
